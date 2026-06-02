import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/spaced_repetition/domain/entities/review_queue_item.dart';
import 'package:snapstudy/features/spaced_repetition/domain/entities/spaced_repetition_stats.dart';

abstract interface class SpacedRepetitionRepository {
  Future<Result<List<ReviewQueueItem>>> getDueQueue({String? sessionId});

  Future<Result<SpacedRepetitionStats>> getStats();

  Future<Result<void>> recordReview({
    required String sessionId,
    required String cardId,
    required ReviewRating rating,
  });
}
