import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_line.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_text_block.dart';
import 'package:snapstudy/features/ocr/domain/services/ocr_layout_formatter.dart';

void main() {
  test('formats question and options from blocks', () {
    const capture = CaptureOcrResult(
      captureId: '1',
      imagePath: '/a.jpg',
      text: 'raw',
      blocks: [
        OcrTextBlock(
          text: 'CÂU HỎI 4',
          confidence: 0.9,
          lines: [OcrLine(text: 'CÂU HỎI 4', confidence: 0.9)],
        ),
        OcrTextBlock(
          text: 'a) Đáp án A',
          confidence: 0.9,
          lines: [OcrLine(text: 'a) Đáp án A', confidence: 0.9)],
        ),
      ],
      confidence: 0.9,
      hasEquations: false,
      status: OcrStatus.completed,
    );

    final out = OcrLayoutFormatter.fromCapture(capture);
    expect(out, contains('CÂU HỎI 4'));
    expect(out, contains('a. Đáp án A'));
  });
}
