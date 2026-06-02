import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/quiz/data/services/mock_quiz_generator.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

void main() {
  test('mock quiz has at least 5 questions', () {
    final session = StudySession(
      id: 'sess-1',
      subjectId: 'sub-1',
      subjectName: 'Toán',
      subjectColorValue: 0xFF2196F3,
      title: 'Chương 1',
      startedAt: DateTime(2025, 1, 1),
      status: SessionStatus.completed,
    );

    final quiz = MockQuizGenerator.generate(session: session);
    expect(quiz.isReady, isTrue);
    expect(quiz.questions.length, greaterThanOrEqualTo(5));
    expect(quiz.questions.first.choices.length, 4);
  });
}
