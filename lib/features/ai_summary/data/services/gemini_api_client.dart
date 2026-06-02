import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/performance/inflight_guard.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_json_utils.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';

class _GeneratePayload {
  const _GeneratePayload({this.text, this.finishReason});

  final String? text;
  final String? finishReason;
}

/// Calls Google Gemini generateContent API (JSON mode).
class GeminiApiClient {
  GeminiApiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static final _inflight = InflightGuard();

  Future<Result<String>> generateJson({
    required String prompt,
    required GeminiAiFeature feature,
    int maxRetries = 3,
  }) async {
    final safePrompt = GeminiTokenLimits.clampPrompt(feature, prompt);
    final key = 'gemini:${feature.name}:${safePrompt.hashCode}:$maxRetries';
    return _inflight.run(
      key,
      () => _generateJsonWithValidation(
        prompt: safePrompt,
        feature: feature,
        networkRetries: maxRetries,
      ),
    );
  }

  Future<Result<String>> _generateJsonWithValidation({
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
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      final response = await _requestGenerateContent(
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
          return const Error(ServerFailure('Gemini trả về rỗng.'));
        }
        continue;
      }

      if (payload.finishReason == 'MAX_TOKENS' ||
          !GeminiJsonUtils.isValidJsonObject(text)) {
        AppLogger.warning(
          'Gemini JSON incomplete (attempt ${jsonAttempt + 1})',
          'finishReason=${payload.finishReason}',
        );
        if (jsonAttempt == jsonAttempts - 1) {
          return const Error(
            ValidationFailure(
              'Gemini trả JSON không đầy đủ. Thử lại sau hoặc rút gọn nội dung OCR.',
            ),
          );
        }
        continue;
      }

      return Success(GeminiJsonUtils.normalize(text));
    }

    return const Error(
      ValidationFailure('Không nhận được JSON hợp lệ từ Gemini.'),
    );
  }

  Future<Result<_GeneratePayload>> _requestGenerateContent({
    required String prompt,
    required int maxOutputTokens,
    required int networkRetries,
  }) async {
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return const Error(
        ValidationFailure('Chưa cấu hình GEMINI_API_KEY trong .env'),
      );
    }

    final url =
        '${EnvConfig.geminiBaseUrl}/v1beta/models/${EnvConfig.geminiModel}:generateContent';

    Object? lastError;
    for (var attempt = 0; attempt < networkRetries; attempt++) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          url,
          queryParameters: {'key': apiKey},
          data: {
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.2,
              'responseMimeType': 'application/json',
              'maxOutputTokens': maxOutputTokens,
            },
          },
        );

        return Success(_parsePayload(response.data));
      } on DioException catch (e) {
        lastError = e;
        final status = e.response?.statusCode;
        AppLogger.warning('Gemini attempt ${attempt + 1} failed', e.message);

        if (status == 429) {
          return Error(ServerFailure(_quotaExceededMessage(e)));
        }

        if (attempt < networkRetries - 1) {
          await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      } catch (e) {
        lastError = e;
        break;
      }
    }

    return Error(ServerFailure('Gemini lỗi: $lastError'));
  }

  _GeneratePayload _parsePayload(Map<String, dynamic>? data) {
    if (data == null) return const _GeneratePayload();

    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return const _GeneratePayload();
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final finishReason = candidate['finishReason'] as String?;
    final content = candidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      return _GeneratePayload(finishReason: finishReason);
    }

    final first = parts.first as Map<String, dynamic>;
    return _GeneratePayload(
      text: first['text'] as String?,
      finishReason: finishReason,
    );
  }

  /// Multimodal OCR — reads text directly from a document photo.
  Future<Result<String>> extractDocumentText({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return const Error(
        ValidationFailure('Chưa cấu hình GEMINI_API_KEY trong .env'),
      );
    }

    if (imageBytes.isEmpty) {
      return const Error(ValidationFailure('Ảnh OCR rỗng.'));
    }

    final url =
        '${EnvConfig.geminiBaseUrl}/v1beta/models/${EnvConfig.geminiModel}:generateContent';

    const prompt = '''
Bạn là hệ thống OCR chuyên nghiệp. Trích xuất TOÀN BỘ văn bản nhìn thấy trong ảnh tài liệu/bài giảng/bài tập.

Quy tắc:
- Giữ đúng ngôn ngữ gốc (tiếng Việt, tiếng Anh, hoặc hỗn hợp)
- Giữ số thứ tự câu hỏi, xuống dòng, bullet như trên ảnh
- Chỉ ghi những gì đọc được rõ; phần mờ ghi [...]
- KHÔNG đoán, KHÔNG bịa, KHÔNG giải thích
- Trả về plain text thuần, không markdown, không JSON
''';

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        queryParameters: {'key': apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Encode(imageBytes),
                  },
                },
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0,
            'maxOutputTokens':
                GeminiTokenLimits.maxOutputTokens(GeminiAiFeature.ocr),
          },
        },
      );

      final payload = _parsePayload(response.data);
      final text = payload.text?.trim();
      if (text == null || text.isEmpty) {
        return const Error(ServerFailure('Gemini Vision không trả về văn bản.'));
      }
      return Success(text);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        return Error(ServerFailure(_quotaExceededMessage(e)));
      }
      return Error(ServerFailure('Gemini Vision lỗi: ${e.message}'));
    } catch (e) {
      return Error(ServerFailure('Gemini Vision lỗi: $e'));
    }
  }

  static String _quotaExceededMessage(DioException e) {
    final apiMessage = _extractApiErrorMessage(e.response?.data);
    if (apiMessage != null &&
        apiMessage.toLowerCase().contains('free_tier')) {
      return 'Hết hạn mức free tier cho model hiện tại (${EnvConfig.geminiModel}). '
          'Đổi GEMINI_MODEL=gemini-2.5-flash trong .env rồi hot restart app. '
          'Hoặc chờ quota reset / bật billing trên Google AI Studio.';
    }
    if (apiMessage != null && apiMessage.contains('retry in')) {
      return 'Gemini quá tải (429). $apiMessage';
    }
    return 'Gemini quá tải (429) — vượt hạn mức request/phút. '
        'Chờ 1–2 phút rồi thử lại; tránh bấm nhiều chức năng liên tiếp.';
  }

  static String? _extractApiErrorMessage(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final error = data['error'];
    if (error is! Map<String, dynamic>) return null;
    return error['message'] as String?;
  }
}
