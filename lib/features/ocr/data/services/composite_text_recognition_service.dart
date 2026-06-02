import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/features/ocr/data/services/text_recognition_service.dart';
import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';

/// Tries cloud vision first, then on-device ML Kit when cloud fails or text is empty.
class CompositeTextRecognitionService implements TextRecognitionService {
  CompositeTextRecognitionService({
    required TextRecognitionService? primary,
    required TextRecognitionService? fallback,
  })  : _primary = primary,
        _fallback = fallback;

  final TextRecognitionService? _primary;
  final TextRecognitionService? _fallback;

  @override
  Future<CaptureOcrResult> recognizeCapture({
    required String captureId,
    required String imagePath,
  }) async {
    if (_primary != null) {
      final primaryResult = await _primary.recognizeCapture(
        captureId: captureId,
        imagePath: imagePath,
      );
      if (_shouldUseResult(primaryResult)) return primaryResult;

      AppLogger.warning(
        'Primary OCR failed or low quality — falling back to ML Kit',
        primaryResult.errorMessage,
      );
    }

    if (_fallback != null) {
      return _fallback.recognizeCapture(
        captureId: captureId,
        imagePath: imagePath,
      );
    }

    return CaptureOcrResult(
      captureId: captureId,
      imagePath: imagePath,
      text: '',
      blocks: const [],
      confidence: 0,
      hasEquations: false,
      status: OcrStatus.failed,
      errorMessage: 'Không có engine OCR khả dụng',
    );
  }

  bool _shouldUseResult(CaptureOcrResult result) {
    if (result.status == OcrStatus.failed) return false;
    if (result.text.trim().length < 8) return false;
    if (result.confidence < 0.45) return false;
    return true;
  }

  @override
  Future<void> dispose() async {
    await _primary?.dispose();
    await _fallback?.dispose();
  }
}
