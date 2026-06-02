import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';

void main() {
  test('clampPrompt respects per-feature total limit', () {
    final long = 'x' * 10000;
    final clamped = GeminiTokenLimits.clampPrompt(
      GeminiAiFeature.summary,
      long,
    );
    expect(clamped.length, lessThanOrEqualTo(7500));
    expect(clamped, contains('...[đã rút gọn]'));
  });

  test('maxOutputTokens differ by feature', () {
    expect(
      GeminiTokenLimits.maxOutputTokens(GeminiAiFeature.summary),
      lessThan(GeminiTokenLimits.maxOutputTokens(GeminiAiFeature.quiz)),
    );
  });
}
