import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/flashcards/domain/repositories/flashcard_repository.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';
import 'package:snapstudy/features/spaced_repetition/data/datasources/review_stats_local_datasource.dart';
import 'package:snapstudy/features/spaced_repetition/domain/entities/review_queue_item.dart';
import 'package:snapstudy/features/spaced_repetition/domain/entities/spaced_repetition_stats.dart';
import 'package:snapstudy/features/spaced_repetition/domain/repositories/spaced_repetition_repository.dart';

class SpacedRepetitionRepositoryImpl implements SpacedRepetitionRepository {
  SpacedRepetitionRepositoryImpl({
    required SessionRepository sessions,
    required FlashcardRepository flashcards,
    ReviewStatsLocalDataSource? statsLocal,
  })  : _sessions = sessions,
        _flashcards = flashcards,
        _stats = statsLocal ?? ReviewStatsLocalDataSource();

  final SessionRepository _sessions;
  final FlashcardRepository _flashcards;
  final ReviewStatsLocalDataSource _stats;

  @override
  Future<Result<List<ReviewQueueItem>>> getDueQueue({String? sessionId}) async {
    final all = await _sessions.getAllSessions();
    return all.fold(
      onSuccess: (sessions) {
        final queue = <ReviewQueueItem>[];
        final now = DateTime.now();

        for (final session in sessions) {
          if (sessionId != null && session.id != sessionId) continue;
          final deck = session.flashcardDeck;
          if (deck == null || !deck.isReady) continue;

          for (final card in deck.cards) {
            if (!card.isDue) continue;

            queue.add(
              ReviewQueueItem(
                sessionId: session.id,
                sessionTitle: session.title,
                subjectName: session.subjectName,
                subjectColorValue: session.subjectColorValue,
                deckTitle: deck.title,
                card: card,
              ),
            );
          }
        }

        queue.sort((a, b) {
          final aDue = a.card.nextReviewAt ?? now;
          final bDue = b.card.nextReviewAt ?? now;
          return aDue.compareTo(bDue);
        });

        return Success(queue);
      },
      onFailure: Error.new,
    );
  }

  @override
  Future<Result<SpacedRepetitionStats>> getStats() async {
    final all = await _sessions.getAllSessions();
    return all.fold(
      onSuccess: (sessions) {
        final now = DateTime.now();
        var dueNow = 0;
        var overdue = 0;
        var dueToday = 0;
        var difficultySum = 0;
        var difficultyCount = 0;
        DateTime? nextReminder;

        for (final s in _sessionsWithDecks(sessions)) {
          for (final card in s.flashcardDeck!.cards) {
            difficultySum += card.difficultyScore;
            difficultyCount++;

            if (!card.isDue) {
              final at = card.nextReviewAt;
              if (at != null && (nextReminder == null || at.isBefore(nextReminder))) {
                nextReminder = at;
              }
              continue;
            }

            dueNow++;
            dueToday++;
            if (card.isOverdue) overdue++;

            final at = card.nextReviewAt ?? now;
            if (nextReminder == null || at.isBefore(nextReminder)) {
              nextReminder = at;
            }
          }
        }

        final retention =
            (_stats.readRetentionEwma() * 100).round().clamp(0, 100);

        return Success(
          SpacedRepetitionStats(
            dueNow: dueNow,
            dueToday: dueToday,
            overdue: overdue,
            reviewedToday: _stats.readReviewedToday(),
            retentionPercent: retention,
            averageDifficulty: difficultyCount == 0
                ? 50
                : (difficultySum / difficultyCount).round(),
            nextReminderAt: nextReminder,
            studyStreakDays: _stats.readStreakDays(),
          ),
        );
      },
      onFailure: Error.new,
    );
  }

  @override
  Future<Result<void>> recordReview({
    required String sessionId,
    required String cardId,
    required ReviewRating rating,
  }) async {
    final result = await _flashcards.recordReview(
      sessionId: sessionId,
      cardId: cardId,
      rating: rating,
    );

    return result.fold(
      onSuccess: (_) async {
        await _stats.incrementReviewedToday();
        await _stats.updateRetentionEwma(rating.sm2Quality);
        return const Success(null);
      },
      onFailure: Error.new,
    );
  }

  Iterable<StudySession> _sessionsWithDecks(List<StudySession> sessions) sync* {
    for (final s in sessions) {
      if (s.flashcardDeck != null && s.flashcardDeck!.isReady) yield s;
    }
  }
}
