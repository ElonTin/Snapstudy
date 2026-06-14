import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai/data/services/llm_json_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_api_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';

class GeminiLlmJsonClient implements LlmJsonClient {
  GeminiLlmJsonClient(this._gemini);

  final GeminiApiClient _gemini;

  @override
  String get providerLabel => 'Gemini';

  @override
  Future<Result<String>> generateJson({
    required String prompt,
    required GeminiAiFeature feature,
    int maxRetries = 3,
  }) =>
      _gemini.generateJson(
        prompt: prompt,
        feature: feature,
        maxRetries: maxRetries,
      );
}
