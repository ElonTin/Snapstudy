import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/features/session_chat/data/models/session_chat_message_model.dart';
import 'package:snapstudy/features/session_chat/domain/entities/session_chat_message.dart';

class SessionChatLocalDataSource {
  static String _key(String sessionId) => 'session_chat:$sessionId';

  Future<List<SessionChatMessage>> readAll(String sessionId) async {
    final raw = HiveService.cacheBox.get(_key(sessionId));
    if (raw is! List) return [];
    return raw
        .map(
          (e) => SessionChatMessageModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ).toEntity(),
        )
        .toList();
  }

  Future<void> saveAll(
    String sessionId,
    List<SessionChatMessage> messages,
  ) async {
    await HiveService.cacheBox.put(
      _key(sessionId),
      messages.map(SessionChatMessageModel.fromEntity).map((m) => m.toJson()).toList(),
    );
  }

  Future<void> clear(String sessionId) async {
    await HiveService.cacheBox.delete(_key(sessionId));
  }
}
