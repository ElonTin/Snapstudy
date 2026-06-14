import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/session_chat/domain/entities/chat_message_role.dart';
import 'package:snapstudy/features/session_chat/domain/entities/session_chat_message.dart';

/// Multi-turn chat — Groq ưu tiên, Gemini fallback.
abstract class LlmChatClient {
  String get providerLabel;

  Future<Result<String>> generateReply({
    required String systemPrompt,
    required List<SessionChatMessage> history,
    required String userMessage,
  });
}

class ChatTurn {
  const ChatTurn({required this.role, required this.content});

  final ChatMessageRole role;
  final String content;
}
