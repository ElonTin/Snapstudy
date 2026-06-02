import 'package:equatable/equatable.dart';

/// Spaced-repetition review due on the dashboard.
class UpcomingReview extends Equatable {
  const UpcomingReview({
    required this.id,
    required this.sessionId,
    required this.deckName,
    required this.subjectName,
    required this.cardCount,
    required this.dueAt,
    required this.subjectColorValue,
  });

  final String id;
  final String sessionId;
  final String deckName;
  final String subjectName;
  final int cardCount;
  final DateTime dueAt;
  final int subjectColorValue;

  bool get isOverdue => dueAt.isBefore(DateTime.now());

  @override
  List<Object?> get props =>
      [id, sessionId, deckName, subjectName, cardCount, dueAt, subjectColorValue];
}
