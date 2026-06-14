import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai/data/services/llm_chat_client.dart';
import 'package:snapstudy/features/session_chat/data/datasources/session_chat_local_datasource.dart';
import 'package:snapstudy/features/session_chat/data/prompts/session_chat_prompt_builder.dart';
import 'package:snapstudy/features/session_chat/domain/entities/chat_message_role.dart';
import 'package:snapstudy/features/session_chat/domain/entities/session_chat_message.dart';
import 'package:snapstudy/features/session_chat/domain/repositories/session_chat_repository.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

class SessionChatRepositoryImpl implements SessionChatRepository {
  SessionChatRepositoryImpl({
    required LlmChatClient chatClient,
    SessionChatLocalDataSource? local,
  })  : _chat = chatClient,
        _local = local ?? SessionChatLocalDataSource();

  final LlmChatClient _chat;
  final SessionChatLocalDataSource _local;

  @override
  Future<List<SessionChatMessage>> getMessages(String sessionId) =>
      _local.readAll(sessionId);

  @override
  Future<void> clearHistory(String sessionId) => _local.clear(sessionId);

  @override
  Future<Result<SessionChatMessage>> sendMessage({
    required StudySession session,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Error(ValidationFailure('Tin nhắn trống.'));
    }

    final history = await _local.readAll(session.id);
    final userMsg = SessionChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatMessageRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );

    if (!EnvConfig.isTextLlmConfigured) {
      final mock = SessionChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch + 1}',
        role: ChatMessageRole.assistant,
        content:
            'Chưa cấu hình AI. Thêm GROQ_API_KEY hoặc GEMINI_API_KEY vào .env để chat.',
        createdAt: DateTime.now(),
      );
      await _local.saveAll(session.id, [...history, userMsg, mock]);
      return Success(mock);
    }

    final reply = await _chat.generateReply(
      systemPrompt: SessionChatPromptBuilder.buildSystemPrompt(session),
      history: history,
      userMessage: trimmed,
    );

    if (reply.isFailure) return Error(reply.failureOrNull!);

    final assistantMsg = SessionChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch + 1}',
      role: ChatMessageRole.assistant,
      content: reply.valueOrNull!,
      createdAt: DateTime.now(),
    );

    await _local.saveAll(session.id, [...history, userMsg, assistantMsg]);
    return Success(assistantMsg);
  }
}
