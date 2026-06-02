import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ocr/data/models/session_ocr_result_model.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';

void main() {
  test('SessionOcrResultModel round-trip json', () {
    final model = SessionOcrResultModel(
      sessionId: 'ses-1',
      fullText: 'Hello lecture',
      captures: const [],
      keywords: const ['hello', 'lecture'],
      averageConfidence: 0.91,
      hasEquations: false,
      status: OcrStatus.completed,
      processedAt: DateTime(2025, 1, 1),
    );

    final restored = SessionOcrResultModel.fromJson(model.toJson());
    expect(restored.sessionId, 'ses-1');
    expect(restored.fullText, 'Hello lecture');
    expect(restored.averageConfidence, 0.91);
    expect(restored.status, OcrStatus.completed);
  });
}
