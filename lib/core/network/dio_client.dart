import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/api_constants.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/network/api_interceptors.dart';
import 'package:snapstudy/core/network/token_refresh_interceptor.dart';

/// Bare Dio for auth endpoints (no refresh interceptor — avoids circular DI).
Dio createBaseDio() {
  return Dio(
    BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': ApiConstants.contentTypeJson,
        'Accept': ApiConstants.acceptJson,
      },
      responseType: ResponseType.json,
    ),
  );
}

/// Main API client with auth + logging + token refresh.
Dio createDioClient(Ref ref) {
  final dio = createBaseDio();

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    if (EnvConfig.isDevelopment) LoggingInterceptor(),
    TokenRefreshInterceptor(ref, dio),
  ]);

  return dio;
}
