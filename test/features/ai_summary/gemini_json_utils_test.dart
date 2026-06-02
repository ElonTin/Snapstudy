import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_json_utils.dart';

void main() {
  test('isValidJsonObject accepts complete object', () {
    expect(
      GeminiJsonUtils.isValidJsonObject('{"title":"Quiz","questions":[]}'),
      isTrue,
    );
  });

  test('isValidJsonObject rejects truncated JSON', () {
    expect(
      GeminiJsonUtils.isValidJsonObject('{"title": "Quiz", "questions": ['),
      isFalse,
    );
  });

  test('normalize strips markdown fences', () {
    expect(
      GeminiJsonUtils.normalize('```json\n{"ok":true}\n```'),
      '{"ok":true}',
    );
  });
}
