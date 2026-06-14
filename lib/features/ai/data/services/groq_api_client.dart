import 'package:dio/dio.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/performance/inflight_guard.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai/data/services/llm_json_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_json_utils.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';

class _GroqPayload {
  const _GroqPayload({this.text, this.finishReason});

  final String? text;
  final String? finishReason;
}

/// Groq OpenAI-compatible API — nhanh cho tóm tắt, phân loại, flashcard, quiz.
class GroqApiClient implements LlmJsonClient {
  GroqApiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static final _inflight = InflightGuard();

  @override
  String get providerLabel => 'Groq';

  @override
  Future<Result<String>> generateJson({
    required String prompt,
    required GeminiAiFeature feature,
    int maxRetries = 3,
  }) async {
    final safePrompt = GeminiTokenLimits.clampPrompt(feature, prompt);
    final key = 'groq:${feature.name}:${safePrompt.hashCode}:$maxRetries';
    return _inflight.run(
      key,
      () => _generateWithValidation(
        prompt: safePrompt,
        feature: feature,
        networkRetries: maxRetries,
      ),
    );
  }

  Future<Result<String>> _generateWithValidation({
    required String prompt,
    required GeminiAiFeature feature,
    required int networkRetries,
  }) async {
    var tokenLimit = GeminiTokenLimits.maxOutputTokens(feature);
    var currentPrompt = prompt;
    const jsonAttempts = 2;

    for (var jsonAttempt = 0; jsonAttempt < jsonAttempts; jsonAttempt++) {
      if (jsonAttempt > 0) {
        currentPrompt = '$prompt\n\n'
            'QUAN TRỌNG: Trả về JSON object HOÀN CHỈNH, đóng đủ ngoặc {}, '
            'không cắt giữa chuỗi. Không markdown.';
        tokenLimit = GeminiTokenLimits.maxOutputTokensRetryCap(feature);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      final response = await _requestChatCompletion(
        prompt: currentPrompt,
        maxOutputTokens: tokenLimit,
        networkRetries: networkRetries,
      );

      if (response.isFailure) {
        if (jsonAttempt == jsonAttempts - 1) {
          return Error(response.failureOrNull!);
        }
        continue;
      }

      final payload = response.valueOrNull!;
      final text = payload.text;
      if (text == null || text.isEmpty) {
        if (jsonAttempt == jsonAttempts - 1) {
          return const Error(ServerFailure('Groq trả về rỗng.'));
        }
        continue;
      }

      if (payload.finishReason == 'length' ||
          !GeminiJsonUtils.isValidJsonObject(text)) {
        AppLogger.warning(
          'Groq JSON incomplete (attempt ${jsonAttempt + 1})',
          'finishReason=${payload.finishReason}',
        );
        if (jsonAttempt == jsonAttempts - 1) {
          return const Error(
            ValidationFailure(
              'Groq trả JSON không đầy đủ. Thử lại sau hoặc rút gọn nội dung OCR.',
            ),
          );
        }
        continue;
      }

      return Success(GeminiJsonUtils.normalize(text));
    }

    return const Error(
      ValidationFailure('Không nhận được JSON hợp lệ từ Groq.'),
    );
  }

  Future<Result<_GroqPayload>> _requestChatCompletion({
    required String prompt,
    required int maxOutputTokens,
    required int networkRetries,
  }) async {
    final apiKey = EnvConfig.groqApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return const Error(
        ValidationFailure('Chưa cấu hình GROQ_API_KEY trong .env'),
      );
    }

    final url = '${EnvConfig.groqBaseUrl}/chat/completions';
    Object? lastError;

    for (var attempt = 0; attempt < networkRetries; attempt++) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          url,
          options: Options(
            headers: {'Authorization': 'Bearer $apiKey'},
          ),
          data: {
            'model': EnvConfig.groqModel,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.2,
            'max_tokens': maxOutputTokens,
            'response_format': {'type': 'json_object'},
          },
        );

        return Success(_parsePayload(response.data));
      } on DioException catch (e) {
        lastError = e;
        AppLogger.warning('Groq attempt ${attempt + 1} failed', e.message);
        if (e.response?.statusCode == 429) {
          return Error(ServerFailure(_rateLimitMessage(e)));
        }
        if (attempt < networkRetries - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 400 * (attempt + 1)),
          );
        }
      } catch (e) {
        lastError = e;
        break;
      }
    }

    return Error(ServerFailure('Groq lỗi: $lastError'));
  }

  _GroqPayload _parsePayload(Map<String, dynamic>? data) {
    if (data == null) return const _GroqPayload();

    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) return const _GroqPayload();

    final choice = choices.first as Map<String, dynamic>;
    final finishReason = choice['finish_reason'] as String?;
    final message = choice['message'] as Map<String, dynamic>?;
    return _GroqPayload(
      text: message?['content'] as String?,
      finishReason: finishReason,
    );
  }

  static String _rateLimitMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final msg = error['message'] as String?;
        if (msg != null) return 'Groq quá tải (429): $msg';
      }
    }
    return 'Groq quá tải (429) — chờ vài giây rồi thử lại.';
  }
}
