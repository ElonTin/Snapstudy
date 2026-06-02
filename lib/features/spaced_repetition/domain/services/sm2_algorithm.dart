import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';

/// SuperMemo 2 scheduling (Phase 11).
abstract final class Sm2Algorithm {
  static const double minEase = 1.3;
  static const double maxEase = 2.5;

  static Flashcard applyReview(Flashcard card, int quality) {
    final q = quality.clamp(0, 5);
    final now = DateTime.now();

    var ease = card.easeFactor;
    var reps = card.repetitions;
    var interval = card.intervalDays;
    var lapses = card.lapses;

    if (q < 3) {
      lapses += 1;
      reps = 0;
      interval = 1;
    } else {
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 6;
      } else {
        interval = (interval * ease).round().clamp(1, 365);
      }
      reps += 1;
    }

    ease += 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
    ease = ease.clamp(minEase, maxEase);

    final nextReviewAt = now.add(Duration(days: interval.clamp(1, 365)));
    final totalReviews = card.totalReviews + 1;
    final difficulty = _difficultyScore(ease: ease, lapses: lapses, reps: reps);

    return card.copyWith(
      repetitions: reps,
      intervalDays: interval,
      easeFactor: ease,
      lapses: lapses,
      nextReviewAt: nextReviewAt,
      lastReviewAt: now,
      lastQuality: q,
      totalReviews: totalReviews,
      difficultyScore: difficulty,
    );
  }

  static Flashcard scheduleNew(Flashcard card) {
    final now = DateTime.now();
    return card.copyWith(
      nextReviewAt: now,
      intervalDays: 0,
      repetitions: 0,
      lapses: 0,
      totalReviews: 0,
      lastQuality: null,
      lastReviewAt: null,
      difficultyScore: 50,
    );
  }

  /// 0 = hardest, 100 = easiest.
  static int _difficultyScore({
    required double ease,
    required int lapses,
    required int reps,
  }) {
    final easePart = ((ease - minEase) / (maxEase - minEase)) * 60;
    final lapsePenalty = (lapses * 12).clamp(0, 50);
    final repBonus = (reps * 4).clamp(0, 30);
    return (easePart + repBonus - lapsePenalty).round().clamp(0, 100);
  }
}
