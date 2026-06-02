import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/flashcards/domain/entities/deck_status.dart';
import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/flashcards/domain/services/sm2_scheduler.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract final class MockFlashcardGenerator {
  static SessionFlashcardDeck generate({
    required StudySession session,
    SessionAiSummary? summary,
  }) {
    final topic = summary?.detectedTopic ?? session.title;
    final points = summary?.keyPoints ?? [session.subjectName];

    final cards = <Flashcard>[
      for (var i = 0; i < points.length && i < 6; i++)
        Sm2Scheduler.scheduleNew(
          Flashcard(
            id: 'fc_mock_${session.id}_$i',
            front: 'Ý ${i + 1}: $topic?',
            back: points[i],
            hint: 'Mẫu dev — bật GEMINI cho thẻ thật',
            tags: [session.subjectName],
          ),
        ),
      Sm2Scheduler.scheduleNew(
        Flashcard(
          id: 'fc_mock_${session.id}_meta',
          front: 'Buổi học này thuộc môn gì?',
          back: session.subjectName,
          tags: const ['meta'],
        ),
      ),
      Sm2Scheduler.scheduleNew(
        Flashcard(
          id: 'fc_mock_${session.id}_title',
          front: 'Tiêu đề buổi học?',
          back: session.title,
          tags: const ['meta'],
        ),
      ),
    ];

    return SessionFlashcardDeck(
      sessionId: session.id,
      title: 'Flashcard: $topic',
      cards: cards,
      status: DeckStatus.completed,
      generatedAt: DateTime.now(),
      modelName: 'mock-dev',
    );
  }
}
