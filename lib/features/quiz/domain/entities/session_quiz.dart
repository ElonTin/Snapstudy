import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_question.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_score_result.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_status.dart';

/// AI-generated MCQ quiz attached to a study session.
class SessionQuiz extends Equatable {
  const SessionQuiz({
    required this.sessionId,
    required this.title,
    required this.questions,
    required this.status,
    required this.generatedAt,
    this.defaultDifficulty = QuizDifficulty.medium,
    this.modelName,
    this.errorMessage,
    this.lastResult,
  });

  final String sessionId;
  final String title;
  final List<QuizQuestion> questions;
  final QuizStatus status;
  final DateTime generatedAt;
  final QuizDifficulty defaultDifficulty;
  final String? modelName;
  final String? errorMessage;
  final QuizScoreResult? lastResult;

  bool get isReady => status == QuizStatus.completed && questions.isNotEmpty;

  List<QuizQuestion> questionsForDifficulty(QuizDifficulty level) {
    if (questions.isEmpty) return [];
    return switch (level) {
      QuizDifficulty.easy => questions
          .where((q) =>
              q.difficulty == QuizDifficulty.easy ||
              q.difficulty == QuizDifficulty.medium)
          .toList(),
      QuizDifficulty.medium => List<QuizQuestion>.from(questions),
      QuizDifficulty.hard => questions
          .where((q) =>
              q.difficulty == QuizDifficulty.hard ||
              q.difficulty == QuizDifficulty.medium)
          .toList(),
    };
  }

  @override
  List<Object?> get props => [
        sessionId,
        title,
        questions,
        status,
        generatedAt,
        defaultDifficulty,
        modelName,
        errorMessage,
        lastResult,
      ];
}
