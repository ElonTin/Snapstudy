import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai/data/services/llm_json_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';

/// Test double for [LlmJsonClient] — returns a fixed result without HTTP.
class FakeLlmJsonClient implements LlmJsonClient {
  FakeLlmJsonClient(this._result);

  final Result<String> _result;

  @override
  String get providerLabel => 'Fake';

  @override
  Future<Result<String>> generateJson({
    required String prompt,
    required GeminiAiFeature feature,
    int maxRetries = 3,
  }) async =>
      _result;
}
