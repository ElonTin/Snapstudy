import 'package:equatable/equatable.dart';

/// Một câu trả lời trong lần làm quiz — dùng phân tích điểm yếu.
class QuizAnswerRecord extends Equatable {
  const QuizAnswerRecord({
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
  });

  final String questionId;
  final int selectedIndex;
  final bool isCorrect;

  @override
  List<Object?> get props => [questionId, selectedIndex, isCorrect];
}
