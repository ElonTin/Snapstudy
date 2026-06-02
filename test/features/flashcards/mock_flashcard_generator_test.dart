import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/summary_status.dart';
import 'package:snapstudy/features/flashcards/data/services/mock_flashcard_generator.dart';
import 'package:snapstudy/features/flashcards/domain/entities/deck_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

void main() {
  test('mock deck has ready cards', () {
    final session = StudySession(
      id: 's1',
      subjectId: 'sub',
      subjectName: 'Toán',
      subjectColorValue: 0xFF0000FF,
      title: 'Buổi 1',
      startedAt: DateTime(2025, 1, 1),
      status: SessionStatus.completed,
    );
    final summary = SessionAiSummary(
      sessionId: 's1',
      detectedTopic: 'Đạo hàm',
      overview: 'Tóm tắt',
      keyPoints: const ['Đạo hàm', 'Cực trị'],
      bulletSummary: const ['a'],
      topics: const ['toán'],
      status: SummaryStatus.completed,
      generatedAt: DateTime(2025, 1, 1),
    );

    final deck = MockFlashcardGenerator.generate(
      session: session,
      summary: summary,
    );

    expect(deck.isReady, true);
    expect(deck.cards.length, greaterThanOrEqualTo(3));
    expect(deck.status, DeckStatus.completed);
  });
}
