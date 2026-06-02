import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ocr/data/services/composite_text_recognition_service.dart';
import 'package:snapstudy/features/ocr/data/services/text_recognition_service.dart';
import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import '../../helpers/test_helpers.dart';

class _StubOcr implements TextRecognitionService {
  _StubOcr(this._result);

  final CaptureOcrResult _result;

  @override
  Future<CaptureOcrResult> recognizeCapture({
    required String captureId,
    required String imagePath,
  }) async =>
      _result;

  @override
  Future<void> dispose() async {}
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  test('composite falls back when primary returns failed', () async {
    const failed = CaptureOcrResult(
      captureId: 'c1',
      imagePath: '/x.jpg',
      text: '',
      blocks: [],
      confidence: 0,
      hasEquations: false,
      status: OcrStatus.failed,
    );
    const ok = CaptureOcrResult(
      captureId: 'c1',
      imagePath: '/x.jpg',
      text: 'Hello world from fallback',
      blocks: [],
      confidence: 0.9,
      hasEquations: false,
      status: OcrStatus.completed,
    );

    final service = CompositeTextRecognitionService(
      primary: _StubOcr(failed),
      fallback: _StubOcr(ok),
    );

    final result = await service.recognizeCapture(
      captureId: 'c1',
      imagePath: '/x.jpg',
    );

    expect(result.text, contains('fallback'));
    await service.dispose();
  });
}
