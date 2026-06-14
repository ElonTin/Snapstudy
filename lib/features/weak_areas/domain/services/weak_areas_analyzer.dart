import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/presentation/utils/session_display_labels.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_item.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_source.dart';

/// Phân tích điểm yếu từ flashcard ratings và quiz sai.
abstract final class WeakAreasAnalyzer {
  WeakAreasAnalyzer._();

  static List<WeakAreaItem> analyzeCards(List<Flashcard> cards) {
    return cards
        .map((card) {
          final score = _flashcardWeaknessScore(card);
          if (score < 20) return null;
          return WeakAreaItem(
            label: _cardLabel(card),
            reason: _flashcardReason(card),
            source: WeakAreaSource.flashcard,
            priorityScore: score,
            referenceId: card.id,
          );
        })
        .whereType<WeakAreaItem>()
        .toList();
  }

  static List<WeakAreaItem> analyzeSession(StudySession session) {
    final items = <WeakAreaItem>[];
    items.addAll(_fromFlashcards(session));
    items.addAll(_fromQuiz(session));
    items.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return items.take(10).toList();
  }

  static List<WeakAreaItem> analyzeAll(List<StudySession> sessions) {
    final items = <WeakAreaItem>[];
    for (final session in sessions) {
      items.addAll(analyzeSession(session));
    }
    items.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return items.take(12).toList();
  }

  static List<WeakAreaItem> _fromFlashcards(StudySession session) {
    final deck = session.flashcardDeck;
    if (deck == null) return [];

    final title = SessionDisplayLabels.title(session);
    return deck.cards
        .map((card) {
          final score = _flashcardWeaknessScore(card);
          if (score < 20) return null;
          return WeakAreaItem(
            label: _cardLabel(card),
            reason: _flashcardReason(card),
            source: WeakAreaSource.flashcard,
            priorityScore: score,
            referenceId: card.id,
            sessionId: session.id,
            sessionTitle: title,
          );
        })
        .whereType<WeakAreaItem>()
        .toList();
  }

  static List<WeakAreaItem> _fromQuiz(StudySession session) {
    final quiz = session.sessionQuiz;
    final result = quiz?.lastResult;
    if (quiz == null || result == null) return [];

    final title = SessionDisplayLabels.title(session);
    final items = <WeakAreaItem>[];

    for (final wrong in result.wrongAnswers) {
      final question = quiz.questions
          .where((q) => q.id == wrong.questionId)
          .firstOrNull;
      if (question == null) continue;
      items.add(
        WeakAreaItem(
          label: _truncate(question.prompt, 80),
          reason: 'Trả lời sai quiz · ${question.difficulty.label}',
          source: WeakAreaSource.quiz,
          priorityScore: 70 + (question.difficulty.index * 5),
          referenceId: question.id,
          sessionId: session.id,
          sessionTitle: title,
        ),
      );
    }

    if (items.isEmpty && result.scorePercent < 70) {
      items.add(
        WeakAreaItem(
          label: SessionDisplayLabels.title(session),
          reason:
              'Điểm quiz ${result.scorePercent}% — cần ôn lại nội dung buổi học',
          source: WeakAreaSource.quiz,
          priorityScore: 100 - result.scorePercent,
          sessionId: session.id,
          sessionTitle: title,
        ),
      );
    }

    return items;
  }

  static int _flashcardWeaknessScore(Flashcard card) {
    var score = 0;
    if (card.lapses > 0) score += card.lapses * 15;
    if (card.lastQuality != null && card.lastQuality! < 3) score += 25;
    if (card.difficultyScore < 40) score += 20;
    if (card.totalReviews > 0 && card.repetitions == 0) score += 15;
    if (card.isOverdue) score += 10;
    return score;
  }

  static String _flashcardReason(Flashcard card) {
    if (card.lastQuality != null && card.lastQuality! < 3) {
      return card.lastQuality == 1
          ? 'Đánh dấu chưa thuộc flashcard'
          : 'Đánh dấu khó / chưa nhớ flashcard';
    }
    if (card.lapses > 0) return 'Quên ${card.lapses} lần';
    if (card.difficultyScore < 40) return 'Thẻ khó (điểm ${card.difficultyScore})';
    return 'Cần ôn lại flashcard';
  }

  static String _cardLabel(Flashcard card) {
    if (card.tags.isNotEmpty) return card.tags.first;
    return _truncate(card.front, 60);
  }

  static String _truncate(String text, int max) {
    final t = text.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max - 1)}…';
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
