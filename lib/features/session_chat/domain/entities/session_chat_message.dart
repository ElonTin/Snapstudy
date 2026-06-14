import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/session_chat/domain/entities/chat_message_role.dart';

class SessionChatMessage extends Equatable {
  const SessionChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final ChatMessageRole role;
  final String content;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, role, content, createdAt];
}
