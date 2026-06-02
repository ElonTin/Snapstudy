import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_score_result.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract interface class QuizRepository {
  Future<Result<SessionQuiz>> generateAndSave({required StudySession session});

  Future<Result<SessionQuiz?>> getQuiz(String sessionId);

  Future<Result<SessionQuiz>> saveScoreResult({
    required String sessionId,
    required QuizScoreResult result,
  });
}
