import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/session_chat/domain/entities/session_chat_message.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract interface class SessionChatRepository {
  Future<List<SessionChatMessage>> getMessages(String sessionId);

  Future<Result<SessionChatMessage>> sendMessage({
    required StudySession session,
    required String text,
  });

  Future<void> clearHistory(String sessionId);
}
