import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_answer_record.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';

/// Latest quiz attempt for score tracking (Phase 12).
class QuizScoreResult extends Equatable {
  const QuizScoreResult({
    required this.difficulty,
    required this.correctCount,
    required this.totalCount,
    required this.completedAt,
    this.answers = const [],
  });

  final QuizDifficulty difficulty;
  final int correctCount;
  final int totalCount;
  final DateTime completedAt;
  final List<QuizAnswerRecord> answers;

  int get scorePercent =>
      totalCount == 0 ? 0 : ((correctCount / totalCount) * 100).round();

  List<QuizAnswerRecord> get wrongAnswers =>
      answers.where((a) => !a.isCorrect).toList();

  @override
  List<Object?> get props =>
      [difficulty, correctCount, totalCount, completedAt, answers];
}
