import 'package:snapstudy/features/ocr/domain/entities/ocr_line.dart';

class OcrLineModel {
  const OcrLineModel({required this.text, required this.confidence});

  factory OcrLineModel.fromJson(Map<String, dynamic> json) => OcrLineModel(
        text: json['text'] as String,
        confidence: (json['confidence'] as num).toDouble(),
      );

  final String text;
  final double confidence;

  Map<String, dynamic> toJson() => {'text': text, 'confidence': confidence};

  OcrLine toEntity() => OcrLine(text: text, confidence: confidence);

  static OcrLineModel fromEntity(OcrLine line) =>
      OcrLineModel(text: line.text, confidence: line.confidence);
}
