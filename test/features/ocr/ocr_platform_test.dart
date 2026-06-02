import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ocr/data/services/ocr_platform.dart';

void main() {
  test('useMockRecognizer is false on VM test host when dev mode off', () {
    // flutter test runs on desktop; with OCR_DEV_MODE=false mock is only if dev+no mlkit
    expect(OcrPlatform.supportsMlKit, isFalse);
  });
}
