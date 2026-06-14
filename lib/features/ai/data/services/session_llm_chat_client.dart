import 'package:dio/dio.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai/data/services/llm_chat_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_api_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/session_chat/domain/entities/chat_message_role.dart';
import 'package:snapstudy/features/session_chat/domain/entities/session_chat_message.dart';

/// Chat buổi học — Groq nhanh, Gemini khi không có Groq.
class SessionLlmChatClient implements LlmChatClient {
  SessionLlmChatClient({
    required Dio groqDio,
    required GeminiApiClient gemini,
  })  : _groqDio = groqDio,
        _gemini = gemini;

  final Dio _groqDio;
  final GeminiApiClient _gemini;

  @override
  String get providerLabel =>
      EnvConfig.isGroqConfigured ? 'Groq' : 'Gemini';

  @override
  Future<Result<String>> generateReply({
    required String systemPrompt,
    required List<SessionChatMessage> history,
    required String userMessage,
  }) async {
    if (EnvConfig.isGroqConfigured) {
      final groq = await _groqChat(
        systemPrompt: systemPrompt,
        history: history,
        userMessage: userMessage,
      );
      if (groq.isSuccess) return groq;
      if (EnvConfig.isGeminiConfigured) {
        AppLogger.warning('Groq chat failed — fallback Gemini', '');
        return _geminiChat(
          systemPrompt: systemPrompt,
          history: history,
          userMessage: userMessage,
        );
      }
      return groq;
    }

    if (EnvConfig.isGeminiConfigured) {
      return _geminiChat(
        systemPrompt: systemPrompt,
        history: history,
        userMessage: userMessage,
      );
    }

    return const Error(
      ValidationFailure('Chưa cấu hình GROQ_API_KEY hoặc GEMINI_API_KEY'),
    );
  }

  Future<Result<String>> _groqChat({
    required String systemPrompt,
    required List<SessionChatMessage> history,
    required String userMessage,
  }) async {
    final apiKey = EnvConfig.groqApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return const Error(ValidationFailure('Chưa cấu hình GROQ_API_KEY'));
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history.take(12).map(
            (m) => {
              'role': m.role == ChatMessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            },
          ),
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await _groqDio.post<Map<String, dynamic>>(
        '${EnvConfig.groqBaseUrl}/chat/completions',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
        data: {
          'model': EnvConfig.groqModel,
          'messages': messages,
          'temperature': 0.5,
          'max_tokens': GeminiTokenLimits.maxOutputTokens(GeminiAiFeature.chat),
        },
      );

      final choices = response.data?['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return const Error(ServerFailure('Groq trả về rỗng.'));
      }
      final message =
          (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      final text = message?['content'] as String?;
      if (text == null || text.trim().isEmpty) {
        return const Error(ServerFailure('Groq trả về rỗng.'));
      }
      return Success(text.trim());
    } on DioException catch (e) {
      return Error(ServerFailure('Groq chat lỗi: ${e.message}'));
    } catch (e) {
      return Error(ServerFailure('Groq chat lỗi: $e'));
    }
  }

  Future<Result<String>> _geminiChat({
    required String systemPrompt,
    required List<SessionChatMessage> history,
    required String userMessage,
  }) async {
    final buffer = StringBuffer()
      ..writeln(systemPrompt)
      ..writeln('\n--- Lịch sử hội thoại ---');
    for (final m in history.take(12)) {
      final who = m.role == ChatMessageRole.user ? 'Học sinh' : 'Trợ lý';
      buffer.writeln('$who: ${m.content}');
    }
    buffer.writeln('\nHọc sinh: $userMessage\nTrợ lý:');

    final prompt = GeminiTokenLimits.clampPrompt(
      GeminiAiFeature.chat,
      buffer.toString(),
    );

    return _gemini.generateText(
      prompt: prompt,
      maxOutputTokens: GeminiTokenLimits.maxOutputTokens(GeminiAiFeature.chat),
    );
  }
}
