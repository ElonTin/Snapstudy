import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_question.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_status.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract final class MockQuizGenerator {
  static SessionQuiz generate({
    required StudySession session,
    SessionAiSummary? summary,
    SessionFlashcardDeck? deck,
  }) {
    final topic = summary?.detectedTopic ?? session.title;
    final points = summary?.keyPoints ?? [session.subjectName, session.title];
    final cards = deck?.cards ?? [];

    final questions = <QuizQuestion>[];

    for (var i = 0; i < points.length && i < 4; i++) {
      final point = points[i];
      questions.add(
        QuizQuestion(
          id: 'q_mock_${session.id}_$i',
          prompt: 'Ý chính ${i + 1} của "$topic" là gì?',
          choices: [
            point,
            'Không liên quan đến bài',
            'Chỉ áp dụng ngoài chương trình',
            'Không có trong tài liệu',
          ],
          correctIndex: 0,
          explanation: 'Đáp án đúng từ tóm tắt AI (chế độ mẫu).',
          difficulty: i.isEven ? QuizDifficulty.easy : QuizDifficulty.medium,
        ),
      );
    }

    if (cards.isNotEmpty) {
      final c = cards.first;
      questions.add(
        QuizQuestion(
          id: 'q_mock_${session.id}_fc',
          prompt: c.front,
          choices: [c.back, 'Đáp án B', 'Đáp án C', 'Đáp án D'],
          correctIndex: 0,
          explanation: 'Trùng với mặt sau flashcard (mẫu dev).',
          difficulty: QuizDifficulty.medium,
        ),
      );
    }

    questions.addAll([
      QuizQuestion(
        id: 'q_mock_${session.id}_subj',
        prompt: 'Buổi học này thuộc môn nào?',
        choices: [
          session.subjectName,
          'Vật lý',
          'Hóa học',
          'Lịch sử',
        ],
        correctIndex: 0,
        explanation: 'Môn được gắn khi tạo buổi học.',
        difficulty: QuizDifficulty.easy,
      ),
      QuizQuestion(
        id: 'q_mock_${session.id}_title',
        prompt: 'Tiêu đề buổi học là gì?',
        choices: [
          session.title,
          'Buổi học khác',
          'Không có tiêu đề',
          'Ôn thi chung',
        ],
        correctIndex: 0,
        explanation: 'Tiêu đề do bạn đặt khi bắt đầu buổi.',
        difficulty: QuizDifficulty.easy,
      ),
      QuizQuestion(
        id: 'q_mock_${session.id}_snap',
        prompt: 'SNAPSTUDY dùng để làm gì?',
        choices: [
          'Chụp tài liệu và ôn tập bằng AI',
          'Chỉ chơi game',
          'Chỉ gửi email',
          'Chỉ xem video',
        ],
        correctIndex: 0,
        explanation: 'Ứng dụng học tập với OCR và AI.',
        difficulty: QuizDifficulty.hard,
      ),
    ]);

    return SessionQuiz(
      sessionId: session.id,
      title: 'Quiz: $topic',
      questions: questions,
      status: QuizStatus.completed,
      generatedAt: DateTime.now(),
      defaultDifficulty: QuizDifficulty.medium,
      modelName: 'mock-dev',
    );
  }
}
