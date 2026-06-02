import 'package:snapstudy/features/ocr/data/services/text_recognition_service.dart';
import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_line.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_text_block.dart';
import 'package:snapstudy/features/ocr/domain/services/equation_detector.dart';

/// Sample OCR for Windows/desktop only — NOT used on Android/iOS by default.
class MockTextRecognitionService implements TextRecognitionService {
  @override
  Future<CaptureOcrResult> recognizeCapture({
    required String captureId,
    required String imagePath,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final sample = '''
[DỮ LIỆU MẪU — không phải OCR thật]
Chỉ hiện trên máy tính khi ML Kit không chạy được.
Ảnh: $imagePath
Chạy app trên điện thoại Android với OCR_DEV_MODE=false để nhận dạng thật.
''';

    final hasEquations = EquationDetector.containsEquations(sample);
    final block = OcrTextBlock(
      text: sample.trim(),
      confidence: 0.5,
      lines: sample
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .map((l) => OcrLine(text: l.trim(), confidence: 0.5))
          .toList(),
    );

    return CaptureOcrResult(
      captureId: captureId,
      imagePath: imagePath,
      text: sample.trim(),
      blocks: [block],
      confidence: 0.5,
      hasEquations: hasEquations,
      status: OcrStatus.partial,
      errorMessage: 'Mock OCR — dùng thiết bị Android để OCR thật',
    );
  }

  @override
  Future<void> dispose() async {}
}
