import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';

/// Abstraction over ML Kit (or dev mock) text recognition.
abstract interface class TextRecognitionService {
  Future<CaptureOcrResult> recognizeCapture({
    required String captureId,
    required String imagePath,
  });

  Future<void> dispose();
}
