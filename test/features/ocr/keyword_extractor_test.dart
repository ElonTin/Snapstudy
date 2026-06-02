import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ocr/domain/services/keyword_extractor.dart';

void main() {
  test('extract returns frequent meaningful words', () {
    const text = '''
Đạo hàm là khái niệm quan trọng trong toán học.
Đạo hàm của hàm số bậc hai.
Bài tập đạo hàm và ứng dụng.
''';

    final keywords = KeywordExtractor.extract(text);
    expect(keywords, contains('đạo'));
    expect(keywords.length, lessThanOrEqualTo(12));
  });
}
