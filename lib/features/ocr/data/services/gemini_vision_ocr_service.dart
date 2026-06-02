import 'dart:convert';

import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_api_client.dart';
import 'package:snapstudy/features/ocr/data/services/ocr_image_prepare.dart';
import 'package:snapstudy/features/ocr/data/services/text_recognition_service.dart';
import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_line.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_text_block.dart';
import 'package:snapstudy/features/ocr/domain/services/equation_detector.dart';

/// Cloud OCR via Gemini multimodal vision — far more accurate on photos of notes.
class GeminiVisionOcrService implements TextRecognitionService {
  GeminiVisionOcrService({required GeminiApiClient gemini}) : _gemini = gemini;

  final GeminiApiClient _gemini;

  @override
  Future<CaptureOcrResult> recognizeCapture({
    required String captureId,
    required String imagePath,
  }) async {
    final payload = await OcrImagePrepare.fromPath(imagePath);
    if (payload == null) {
      return CaptureOcrResult(
        captureId: captureId,
        imagePath: imagePath,
        text: '',
        blocks: const [],
        confidence: 0,
        hasEquations: false,
        status: OcrStatus.failed,
        errorMessage: 'Không đọc được file ảnh',
      );
    }

    final extracted = await _gemini.extractDocumentText(
      imageBytes: payload.bytes,
      mimeType: payload.mimeType,
    );

    return extracted.fold(
      onSuccess: (text) {
        final trimmed = text.trim();
        if (trimmed.isEmpty) {
          return CaptureOcrResult(
            captureId: captureId,
            imagePath: imagePath,
            text: '',
            blocks: const [],
            confidence: 0,
            hasEquations: false,
            status: OcrStatus.partial,
            errorMessage: 'Gemini không thấy văn bản trong ảnh',
          );
        }

        final blocks = _linesToBlocks(trimmed);
        final confidence = _estimateQuality(trimmed);

        return CaptureOcrResult(
          captureId: captureId,
          imagePath: imagePath,
          text: trimmed,
          blocks: blocks,
          confidence: confidence,
          hasEquations: EquationDetector.containsEquations(trimmed),
          status: OcrStatus.completed,
        );
      },
      onFailure: (failure) => CaptureOcrResult(
        captureId: captureId,
        imagePath: imagePath,
        text: '',
        blocks: const [],
        confidence: 0,
        hasEquations: false,
        status: OcrStatus.failed,
        errorMessage: failure.message,
      ),
    );
  }

  List<OcrTextBlock> _linesToBlocks(String text) {
    final lines = const LineSplitter().convert(text);
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map(
          (line) => OcrTextBlock(
            text: line,
            confidence: 0.92,
            lines: [OcrLine(text: line, confidence: 0.92)],
          ),
        )
        .toList();
  }

  double _estimateQuality(String text) {
    if (text.length < 20) return 0.55;
    final readable = RegExp(r'[A-Za-zÀ-ỹ0-9]');
    final matches = readable.allMatches(text).length;
    final ratio = matches / text.length;
    if (ratio >= 0.65) return 0.94;
    if (ratio >= 0.45) return 0.82;
    return 0.68;
  }

  @override
  Future<void> dispose() async {}
}
