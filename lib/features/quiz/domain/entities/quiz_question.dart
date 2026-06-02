import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';

/// One multiple-choice question in a session quiz.
class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
    this.difficulty = QuizDifficulty.medium,
  });

  final String id;
  final String prompt;
  final List<String> choices;
  final int correctIndex;
  final String explanation;
  final QuizDifficulty difficulty;

  bool isCorrectAnswer(int selectedIndex) => selectedIndex == correctIndex;

  @override
  List<Object?> get props => [
        id,
        prompt,
        choices,
        correctIndex,
        explanation,
        difficulty,
      ];
}
