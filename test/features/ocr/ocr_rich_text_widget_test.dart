import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ocr/presentation/widgets/ocr_rich_text_widget.dart';

void main() {
  test('parse splits inline and block latex', () {
    const input = r'Công thức $x^2+1$ và $$\frac{a}{b}$$';
    final segments = OcrRichTextWidget.parse(input);

    final inline = segments.firstWhere((s) => s.isLatex && !s.isBlock);
    final block = segments.firstWhere((s) => s.isBlock);

    expect(inline.text, 'x^2+1');
    expect(block.text, r'\frac{a}{b}');
  });
}
