import 'package:dio/dio.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_api_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';

/// Test double for [GeminiApiClient] — returns a fixed result without HTTP.
class FakeGeminiApiClient extends GeminiApiClient {
  FakeGeminiApiClient(this._result, {Dio? dio}) : super(dio: dio ?? Dio());

  final Result<String> _result;

  @override
  Future<Result<String>> generateJson({
    required String prompt,
    required GeminiAiFeature feature,
    int maxRetries = 3,
  }) async =>
      _result;
}
