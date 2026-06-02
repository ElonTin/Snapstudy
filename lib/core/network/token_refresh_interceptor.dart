import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/api_constants.dart';
import 'package:snapstudy/core/di/providers.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/features/auth/presentation/providers/auth_providers.dart';

/// On 401, refreshes JWT via auth datasources and retries once.
class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor(this._ref, this._dio);

  final Ref _ref;
  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final path = err.requestOptions.path;
    if (path.contains(ApiConstants.authRefresh) ||
        path.contains(ApiConstants.authGoogle) ||
        path.contains(ApiConstants.authLogin)) {
      return handler.next(err);
    }

    try {
      final local = _ref.read(authLocalDataSourceProvider);
      final remote = _ref.read(authRemoteDataSourceProvider);
      final current = await local.readSession();

      if (current == null) {
        await _ref.read(authControllerProvider.notifier).signOut();
        return handler.next(err);
      }

      final dto = await remote.refreshToken(current.tokens.refreshToken);
      final session = dto.toSession();
      await local.saveSession(session);

      _ref.read(authTokenProvider.notifier).state = session.tokens.accessToken;
      _ref.invalidate(authControllerProvider);

      final opts = err.requestOptions;
      opts.headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix}${session.tokens.accessToken}';

      final response = await _dio.fetch<dynamic>(opts);
      handler.resolve(response);
    } catch (e, st) {
      AppLogger.error('Token refresh failed', e, st);
      await _ref.read(authControllerProvider.notifier).signOut();
      handler.next(err);
    }
  }
}
