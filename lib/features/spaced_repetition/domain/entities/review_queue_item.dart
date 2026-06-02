import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';

/// A due card in the global review queue.
class ReviewQueueItem extends Equatable {
  const ReviewQueueItem({
    required this.sessionId,
    required this.sessionTitle,
    required this.subjectName,
    required this.subjectColorValue,
    required this.deckTitle,
    required this.card,
  });

  final String sessionId;
  final String sessionTitle;
  final String subjectName;
  final int subjectColorValue;
  final String deckTitle;
  final Flashcard card;

  @override
  List<Object?> get props => [
        sessionId,
        sessionTitle,
        subjectName,
        subjectColorValue,
        deckTitle,
        card,
      ];
}
