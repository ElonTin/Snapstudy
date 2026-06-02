import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_line.dart';

class OcrTextBlock extends Equatable {
  const OcrTextBlock({
    required this.text,
    required this.confidence,
    this.lines = const [],
  });

  final String text;
  final double confidence;
  final List<OcrLine> lines;

  @override
  List<Object?> get props => [text, confidence, lines];
}
