import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_score_result.dart';

class QuizScoreResultModel {
  const QuizScoreResultModel({
    required this.difficulty,
    required this.correctCount,
    required this.totalCount,
    required this.completedAt,
  });

  factory QuizScoreResultModel.fromJson(Map<String, dynamic> json) {
    return QuizScoreResultModel(
      difficulty:
          QuizDifficulty.values.byName(json['difficulty'] as String),
      correctCount: json['correctCount'] as int,
      totalCount: json['totalCount'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  final QuizDifficulty difficulty;
  final int correctCount;
  final int totalCount;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty.name,
        'correctCount': correctCount,
        'totalCount': totalCount,
        'completedAt': completedAt.toIso8601String(),
      };

  QuizScoreResult toEntity() => QuizScoreResult(
        difficulty: difficulty,
        correctCount: correctCount,
        totalCount: totalCount,
        completedAt: completedAt,
      );

  static QuizScoreResultModel fromEntity(QuizScoreResult r) =>
      QuizScoreResultModel(
        difficulty: r.difficulty,
        correctCount: r.correctCount,
        totalCount: r.totalCount,
        completedAt: r.completedAt,
      );
}
