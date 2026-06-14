import 'package:snapstudy/features/quiz/domain/entities/quiz_answer_record.dart';

class QuizAnswerRecordModel {
  const QuizAnswerRecordModel({
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
  });

  factory QuizAnswerRecordModel.fromJson(Map<String, dynamic> json) {
    return QuizAnswerRecordModel(
      questionId: json['questionId'] as String,
      selectedIndex: json['selectedIndex'] as int,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  final String questionId;
  final int selectedIndex;
  final bool isCorrect;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'selectedIndex': selectedIndex,
        'isCorrect': isCorrect,
      };

  QuizAnswerRecord toEntity() => QuizAnswerRecord(
        questionId: questionId,
        selectedIndex: selectedIndex,
        isCorrect: isCorrect,
      );

  static QuizAnswerRecordModel fromEntity(QuizAnswerRecord r) =>
      QuizAnswerRecordModel(
        questionId: r.questionId,
        selectedIndex: r.selectedIndex,
        isCorrect: r.isCorrect,
      );
}
