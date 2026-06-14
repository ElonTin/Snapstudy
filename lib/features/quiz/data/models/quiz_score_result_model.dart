import 'package:snapstudy/features/quiz/data/models/quiz_answer_record_model.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_score_result.dart';

class QuizScoreResultModel {
  const QuizScoreResultModel({
    required this.difficulty,
    required this.correctCount,
    required this.totalCount,
    required this.completedAt,
    this.answers = const [],
  });

  factory QuizScoreResultModel.fromJson(Map<String, dynamic> json) {
    final answersRaw = json['answers'] as List<dynamic>? ?? [];
    return QuizScoreResultModel(
      difficulty:
          QuizDifficulty.values.byName(json['difficulty'] as String),
      correctCount: json['correctCount'] as int,
      totalCount: json['totalCount'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      answers: answersRaw
          .map(
            (e) => QuizAnswerRecordModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  final QuizDifficulty difficulty;
  final int correctCount;
  final int totalCount;
  final DateTime completedAt;
  final List<QuizAnswerRecordModel> answers;

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty.name,
        'correctCount': correctCount,
        'totalCount': totalCount,
        'completedAt': completedAt.toIso8601String(),
        if (answers.isNotEmpty)
          'answers': answers.map((a) => a.toJson()).toList(),
      };

  QuizScoreResult toEntity() => QuizScoreResult(
        difficulty: difficulty,
        correctCount: correctCount,
        totalCount: totalCount,
        completedAt: completedAt,
        answers: answers.map((a) => a.toEntity()).toList(),
      );

  static QuizScoreResultModel fromEntity(QuizScoreResult r) =>
      QuizScoreResultModel(
        difficulty: r.difficulty,
        correctCount: r.correctCount,
        totalCount: r.totalCount,
        completedAt: r.completedAt,
        answers: r.answers.map(QuizAnswerRecordModel.fromEntity).toList(),
      );
}
