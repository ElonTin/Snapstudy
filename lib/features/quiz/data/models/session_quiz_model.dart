import 'package:snapstudy/features/quiz/data/models/quiz_question_model.dart';
import 'package:snapstudy/features/quiz/data/models/quiz_score_result_model.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_status.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';

class SessionQuizModel {
  const SessionQuizModel({
    required this.sessionId,
    required this.title,
    required this.questions,
    required this.status,
    required this.generatedAt,
    required this.defaultDifficulty,
    this.modelName,
    this.errorMessage,
    this.lastResult,
  });

  factory SessionQuizModel.fromJson(Map<String, dynamic> json) {
    final questionsRaw = json['questions'] as List<dynamic>? ?? [];
    return SessionQuizModel(
      sessionId: json['sessionId'] as String,
      title: json['title'] as String,
      questions: questionsRaw
          .map((e) => QuizQuestionModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      status: QuizStatus.values.byName(json['status'] as String),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      defaultDifficulty: QuizDifficulty.values
          .byName(json['defaultDifficulty'] as String? ?? 'medium'),
      modelName: json['modelName'] as String?,
      errorMessage: json['errorMessage'] as String?,
      lastResult: json['lastResult'] != null
          ? QuizScoreResultModel.fromJson(
              Map<String, dynamic>.from(json['lastResult'] as Map),
            )
          : null,
    );
  }

  final String sessionId;
  final String title;
  final List<QuizQuestionModel> questions;
  final QuizStatus status;
  final DateTime generatedAt;
  final QuizDifficulty defaultDifficulty;
  final String? modelName;
  final String? errorMessage;
  final QuizScoreResultModel? lastResult;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'title': title,
        'questions': questions.map((q) => q.toJson()).toList(),
        'status': status.name,
        'generatedAt': generatedAt.toIso8601String(),
        'defaultDifficulty': defaultDifficulty.name,
        if (modelName != null) 'modelName': modelName,
        if (errorMessage != null) 'errorMessage': errorMessage,
        if (lastResult != null) 'lastResult': lastResult!.toJson(),
      };

  SessionQuiz toEntity() => SessionQuiz(
        sessionId: sessionId,
        title: title,
        questions: questions.map((q) => q.toEntity()).toList(),
        status: status,
        generatedAt: generatedAt,
        defaultDifficulty: defaultDifficulty,
        modelName: modelName,
        errorMessage: errorMessage,
        lastResult: lastResult?.toEntity(),
      );

  static SessionQuizModel fromEntity(SessionQuiz quiz) => SessionQuizModel(
        sessionId: quiz.sessionId,
        title: quiz.title,
        questions: quiz.questions.map(QuizQuestionModel.fromEntity).toList(),
        status: quiz.status,
        generatedAt: quiz.generatedAt,
        defaultDifficulty: quiz.defaultDifficulty,
        modelName: quiz.modelName,
        errorMessage: quiz.errorMessage,
        lastResult: quiz.lastResult != null
            ? QuizScoreResultModel.fromEntity(quiz.lastResult!)
            : null,
      );
}
