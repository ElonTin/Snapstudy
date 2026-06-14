import 'package:equatable/equatable.dart';

/// Kết quả AI phân loại môn học từ nội dung ảnh/OCR.
class AiSubjectClassification extends Equatable {
  const AiSubjectClassification({
    required this.subjectName,
    required this.confidence,
    this.educationLevel,
    this.topic,
  });

  /// Tên môn (VD: Toán học, Vật lý, Ngữ văn, Lập trình C++).
  final String subjectName;

  /// Cấp học (VD: Lớp 10, THPT, Đại học).
  final String? educationLevel;

  /// Chủ đề bài trong ảnh (VD: Tích phân – ứng dụng).
  final String? topic;

  final double confidence;

  String get displayLabel {
    if (educationLevel != null && educationLevel!.isNotEmpty) {
      return '$subjectName · $educationLevel';
    }
    return subjectName;
  }

  @override
  List<Object?> get props => [subjectName, educationLevel, topic, confidence];
}
