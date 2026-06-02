import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_api_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import '../../helpers/dio_test_helper.dart';
import '../../helpers/session_fixtures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  test('parses successful Gemini JSON response', () async {
    final mockDio = createMockDio(
      response: Response(
        requestOptions: RequestOptions(path: '/'),
        data: geminiSuccessPayload(validSummaryJson),
        statusCode: 200,
      ),
    );
    final mockClient = GeminiApiClient(dio: mockDio);
    final result = await mockClient.generateJson(
      prompt: 'test',
      feature: GeminiAiFeature.summary,
    );

    expect(result.isSuccess, true);
    expect(result.valueOrNull, contains('detectedTopic'));
  });

  test('returns ServerFailure when response has no text', () async {
    final mockDio = createMockDio(
      response: Response(
        requestOptions: RequestOptions(path: '/'),
        data: {'candidates': []},
        statusCode: 200,
      ),
    );
    final client = GeminiApiClient(dio: mockDio);
    final result = await client.generateJson(
      prompt: 'empty',
      feature: GeminiAiFeature.summary,
    );

    expect(result.isFailure, true);
    expect(result.failureOrNull, isA<ServerFailure>());
  });

  test('coalesces duplicate in-flight prompts', () async {
    var callCount = 0;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          callCount++;
          await Future<void>.delayed(const Duration(milliseconds: 30));
          handler.resolve(
            Response(
              requestOptions: options,
              data: geminiSuccessPayload('{"ok":true}'),
              statusCode: 200,
            ),
          );
        },
      ),
    );

    final client = GeminiApiClient(dio: dio);
    final a = client.generateJson(
      prompt: 'same-prompt',
      feature: GeminiAiFeature.summary,
    );
    final b = client.generateJson(
      prompt: 'same-prompt',
      feature: GeminiAiFeature.summary,
    );
    await Future.wait([a, b]);

    expect(callCount, 1);
  });
}
