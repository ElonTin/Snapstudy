import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';

/// Giao diện chung cho LLM trả JSON (Groq hoặc Gemini text).
abstract class LlmJsonClient {
  String get providerLabel;

  Future<Result<String>> generateJson({
    required String prompt,
    required GeminiAiFeature feature,
    int maxRetries = 3,
  });
}
