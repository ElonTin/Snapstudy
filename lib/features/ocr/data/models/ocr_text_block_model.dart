import 'package:snapstudy/features/ocr/data/models/ocr_line_model.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_text_block.dart';

class OcrTextBlockModel {
  const OcrTextBlockModel({
    required this.text,
    required this.confidence,
    this.lines = const [],
  });

  factory OcrTextBlockModel.fromJson(Map<String, dynamic> json) {
    final linesRaw = json['lines'] as List<dynamic>? ?? [];
    return OcrTextBlockModel(
      text: json['text'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      lines: linesRaw
          .map((e) => OcrLineModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  final String text;
  final double confidence;
  final List<OcrLineModel> lines;

  Map<String, dynamic> toJson() => {
        'text': text,
        'confidence': confidence,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  OcrTextBlock toEntity() => OcrTextBlock(
        text: text,
        confidence: confidence,
        lines: lines.map((l) => l.toEntity()).toList(),
      );

  static OcrTextBlockModel fromEntity(OcrTextBlock block) => OcrTextBlockModel(
        text: block.text,
        confidence: block.confidence,
        lines: block.lines.map(OcrLineModel.fromEntity).toList(),
      );
}
