import 'package:dio/dio.dart';

/// Dio instance that resolves all requests with a fixed [Response].
Dio createMockDio({
  required Response<dynamic> response,
  BaseOptions? baseOptions,
}) {
  final dio = Dio(baseOptions ?? BaseOptions());
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(response),
    ),
  );
  return dio;
}

Map<String, dynamic> geminiSuccessPayload(String text) => {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    };
