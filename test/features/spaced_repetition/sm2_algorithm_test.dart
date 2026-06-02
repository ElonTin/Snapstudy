import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/spaced_repetition/domain/services/sm2_algorithm.dart';

void main() {
  test('SM-2 good increases interval on second rep', () {
    var card = Sm2Algorithm.scheduleNew(
      const Flashcard(id: '1', front: 'Q', back: 'A'),
    );
    card = Sm2Algorithm.applyReview(card, ReviewRating.good.sm2Quality);
    expect(card.repetitions, 1);
    expect(card.intervalDays, 1);

    card = Sm2Algorithm.applyReview(card, ReviewRating.good.sm2Quality);
    expect(card.repetitions, 2);
    expect(card.intervalDays, 6);
  });

  test('SM-2 again resets repetitions and increments lapses', () {
    final card = const Flashcard(
      id: '1',
      front: 'Q',
      back: 'A',
      repetitions: 2,
      intervalDays: 6,
      lapses: 0,
    );
    final reviewed = Sm2Algorithm.applyReview(card, ReviewRating.again.sm2Quality);
    expect(reviewed.repetitions, 0);
    expect(reviewed.lapses, 1);
    expect(reviewed.intervalDays, 1);
  });

  test('records lastQuality and totalReviews', () {
    final card = Sm2Algorithm.scheduleNew(
      const Flashcard(id: '1', front: 'Q', back: 'A'),
    );
    final reviewed = Sm2Algorithm.applyReview(card, ReviewRating.easy.sm2Quality);
    expect(reviewed.totalReviews, 1);
    expect(reviewed.lastQuality, 5);
    expect(reviewed.lastReviewAt, isNotNull);
  });
}
