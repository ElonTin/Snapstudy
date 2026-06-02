import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_text_block.dart';

/// OCR output for a single captured image.
class CaptureOcrResult extends Equatable {
  const CaptureOcrResult({
    required this.captureId,
    required this.imagePath,
    required this.text,
    required this.blocks,
    required this.confidence,
    required this.hasEquations,
    required this.status,
    this.errorMessage,
  });

  final String captureId;
  final String imagePath;
  final String text;
  final List<OcrTextBlock> blocks;
  final double confidence;
  final bool hasEquations;
  final OcrStatus status;
  final String? errorMessage;

  bool get isSuccess =>
      (status == OcrStatus.completed || status == OcrStatus.partial) &&
      text.trim().isNotEmpty;

  @override
  List<Object?> get props => [
        captureId,
        imagePath,
        text,
        blocks,
        confidence,
        hasEquations,
        status,
        errorMessage,
      ];
}
