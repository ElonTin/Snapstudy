import 'package:snapstudy/features/session_chat/domain/entities/chat_message_role.dart';
import 'package:snapstudy/features/session_chat/domain/entities/session_chat_message.dart';

class SessionChatMessageModel {
  const SessionChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory SessionChatMessageModel.fromJson(Map<String, dynamic> json) {
    return SessionChatMessageModel(
      id: json['id'] as String,
      role: ChatMessageRole.values.byName(json['role'] as String),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final ChatMessageRole role;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  SessionChatMessage toEntity() => SessionChatMessage(
        id: id,
        role: role,
        content: content,
        createdAt: createdAt,
      );

  static SessionChatMessageModel fromEntity(SessionChatMessage m) =>
      SessionChatMessageModel(
        id: m.id,
        role: m.role,
        content: m.content,
        createdAt: m.createdAt,
      );
}
