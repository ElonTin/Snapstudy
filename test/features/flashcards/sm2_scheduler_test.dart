import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/flashcards/domain/services/sm2_scheduler.dart';

void main() {
  test('good rating increases repetitions', () {
    final card = Sm2Scheduler.scheduleNew(
      const Flashcard(id: '1', front: 'Q', back: 'A'),
    );
    final reviewed = Sm2Scheduler.applyReview(card, ReviewRating.good);
    expect(reviewed.repetitions, 1);
    expect(reviewed.intervalDays, greaterThanOrEqualTo(1));
  });

  test('again resets repetitions', () {
    final card = const Flashcard(
      id: '1',
      front: 'Q',
      back: 'A',
      repetitions: 2,
      intervalDays: 6,
      lapses: 0,
    );
    final reviewed = Sm2Scheduler.applyReview(card, ReviewRating.again);
    expect(reviewed.repetitions, 0);
    expect(reviewed.lapses, 1);
    expect(reviewed.intervalDays, 1);
  });

  test('hard maps to quality 3', () {
    expect(ReviewRating.hard.sm2Quality, 3);
  });
}
