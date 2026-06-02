import 'package:equatable/equatable.dart';

enum AiActivityType { summary, flashcards, quiz, mindmap, ocr }

/// AI pipeline activity feed item.
class AiActivityItem extends Equatable {
  const AiActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.createdAt,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String subtitle;
  final AiActivityType type;
  final DateTime createdAt;
  final bool isCompleted;

  @override
  List<Object?> get props =>
      [id, title, subtitle, type, createdAt, isCompleted];
}
