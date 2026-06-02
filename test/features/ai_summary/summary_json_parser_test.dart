import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ai_summary/data/services/summary_json_parser.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/summary_status.dart';

void main() {
  const sessionId = 'sess-1';

  test('parse valid JSON', () {
    const raw = '''
{
  "detectedTopic": "Đạo hàm",
  "overview": "Buổi học về đạo hàm cơ bản.",
  "keyPoints": ["Định nghĩa", "Quy tắc"],
  "bulletSummary": ["f'(x)", "Ứng dụng"],
  "topics": ["Toán", "Calculus"]
}
''';

    final result = SummaryJsonParser.parse(
      sessionId: sessionId,
      rawJson: raw,
      modelName: 'gemini-2.0-flash',
    );

    expect(result.isSuccess, true);
    final summary = result.valueOrNull!;
    expect(summary.sessionId, sessionId);
    expect(summary.detectedTopic, 'Đạo hàm');
    expect(summary.keyPoints.length, 2);
    expect(summary.status, SummaryStatus.completed);
    expect(summary.modelName, 'gemini-2.0-flash');
  });

  test('parse strips markdown fences', () {
    const raw = '''
```json
{
  "detectedTopic": "Vật lý",
  "overview": "Tóm tắt.",
  "keyPoints": ["a"],
  "bulletSummary": ["b"],
  "topics": ["c"]
}
```
''';

    final result = SummaryJsonParser.parse(
      sessionId: sessionId,
      rawJson: raw,
    );

    expect(result.isSuccess, true);
    expect(result.valueOrNull?.detectedTopic, 'Vật lý');
  });

  test('parse fails on missing keyPoints', () {
    const raw = '''
{
  "detectedTopic": "X",
  "overview": "Y",
  "keyPoints": [],
  "bulletSummary": ["b"],
  "topics": ["c"]
}
''';

    final result = SummaryJsonParser.parse(
      sessionId: sessionId,
      rawJson: raw,
    );

    expect(result.isFailure, true);
  });
}
