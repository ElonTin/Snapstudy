import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_question.dart';

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.id,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      choices: (json['choices'] as List<dynamic>).cast<String>(),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      difficulty: QuizDifficulty.values.byName(json['difficulty'] as String),
    );
  }

  final String id;
  final String prompt;
  final List<String> choices;
  final int correctIndex;
  final String explanation;
  final QuizDifficulty difficulty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'choices': choices,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'difficulty': difficulty.name,
      };

  QuizQuestion toEntity() => QuizQuestion(
        id: id,
        prompt: prompt,
        choices: choices,
        correctIndex: correctIndex,
        explanation: explanation,
        difficulty: difficulty,
      );

  static QuizQuestionModel fromEntity(QuizQuestion q) => QuizQuestionModel(
        id: q.id,
        prompt: q.prompt,
        choices: q.choices,
        correctIndex: q.correctIndex,
        explanation: q.explanation,
        difficulty: q.difficulty,
      );
}
