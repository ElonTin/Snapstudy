import 'package:equatable/equatable.dart';

/// A single flashcard scheduled for future review notification.
class CardReviewReminder extends Equatable {
  const CardReviewReminder({
    required this.cardId,
    required this.sessionId,
    required this.sessionTitle,
    required this.cardFront,
    required this.reviewAt,
  });

  final String cardId;
  final String sessionId;
  final String sessionTitle;
  final String cardFront;
  final DateTime reviewAt;

  @override
  List<Object?> get props => [cardId, sessionId, sessionTitle, cardFront, reviewAt];
}
