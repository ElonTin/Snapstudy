import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/spaced_repetition/domain/services/sm2_algorithm.dart';

/// Delegates to [Sm2Algorithm] (Phase 11).
abstract final class Sm2Scheduler {
  static Flashcard applyReview(Flashcard card, ReviewRating rating) {
    return Sm2Algorithm.applyReview(card, rating.sm2Quality);
  }

  static Flashcard scheduleNew(Flashcard card) {
    return Sm2Algorithm.scheduleNew(card);
  }
}
