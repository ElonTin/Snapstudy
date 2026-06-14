import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/flashcards/domain/entities/deck_status.dart';
import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_answer_record.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_question.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_score_result.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_status.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_source.dart';
import 'package:snapstudy/features/weak_areas/domain/services/weak_areas_analyzer.dart';

void main() {
  test('detects weak flashcards from lapses and low quality', () {
    final session = StudySession(
      id: 's1',
      subjectId: 'math',
      subjectName: 'Toán',
      subjectColorValue: 0xFF0000FF,
      title: 'Xác suất',
      startedAt: DateTime(2026, 1, 1),
      status: SessionStatus.ready,
      flashcardDeck: SessionFlashcardDeck(
        sessionId: 's1',
        title: 'Deck',
        status: DeckStatus.completed,
        cards: [
          const Flashcard(
            id: 'c1',
            front: 'P(A)',
            back: 'xác suất A',
            lapses: 2,
            lastQuality: 1,
            difficultyScore: 20,
          ),
          const Flashcard(
            id: 'c2',
            front: 'Dễ',
            back: 'ok',
            difficultyScore: 90,
          ),
        ],
        generatedAt: DateTime(2026, 1, 1),
      ),
    );

    final items = WeakAreasAnalyzer.analyzeSession(session);
    expect(items, isNotEmpty);
    expect(items.first.source, WeakAreaSource.flashcard);
    expect(items.first.referenceId, 'c1');
  });

  test('detects quiz wrong answers', () {
    final session = StudySession(
      id: 's2',
      subjectId: 'math',
      subjectName: 'Toán',
      subjectColorValue: 0xFF0000FF,
      title: 'Quiz',
      startedAt: DateTime(2026, 1, 1),
      status: SessionStatus.ready,
      sessionQuiz: SessionQuiz(
        sessionId: 's2',
        title: 'Quiz 1',
        status: QuizStatus.completed,
        questions: [
          const QuizQuestion(
            id: 'q1',
            prompt: 'Công thức xác suất?',
            choices: ['A', 'B', 'C', 'D'],
            correctIndex: 0,
            explanation: '...',
            difficulty: QuizDifficulty.hard,
          ),
        ],
        generatedAt: DateTime(2026, 1, 1),
        lastResult: QuizScoreResult(
          difficulty: QuizDifficulty.medium,
          correctCount: 0,
          totalCount: 1,
          completedAt: DateTime(2026, 1, 2),
          answers: [
            const QuizAnswerRecord(
              questionId: 'q1',
              selectedIndex: 2,
              isCorrect: false,
            ),
          ],
        ),
      ),
    );

    final items = WeakAreasAnalyzer.analyzeSession(session);
    expect(items.any((i) => i.source == WeakAreaSource.quiz), isTrue);
  });
}
