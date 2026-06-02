import 'package:equatable/equatable.dart';

class OcrLine extends Equatable {
  const OcrLine({
    required this.text,
    required this.confidence,
  });

  final String text;
  final double confidence;

  @override
  List<Object?> get props => [text, confidence];
}
