import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/network/api_exception_mapper.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';

/// Registers FCM device tokens with SNAPSTUDY backend for server push.
class PushRegistrationApi {
  PushRegistrationApi({Dio? dio}) : _dio = dio ?? Dio(_baseOptions);

  final Dio _dio;

  static BaseOptions get _baseOptions => BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      );

  Future<Result<void>> registerDevice({
    required String fcmToken,
    String? userId,
    String? authBearer,
  }) async {
    if (!EnvConfig.enablePushRegistration) {
      return const Success(null);
    }

    try {
      final platform = _platformName();
      await _dio.post<void>(
        EnvConfig.pushRegisterPath,
        data: {
          'fcmToken': fcmToken,
          'platform': platform,
          'userId': ?userId,
        },
        options: Options(
          headers: authBearer != null
              ? {'Authorization': 'Bearer $authBearer'}
              : null,
        ),
      );
      AppLogger.info('FCM token registered with server ($platform)');
      return const Success(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        AppLogger.warning(
          'Push register endpoint not found — backend chưa triển khai ${EnvConfig.pushRegisterPath}',
        );
        return const Success(null);
      }
      return Error(mapDioException(e).toFailure());
    } catch (e) {
      return Error(UnknownFailure('Đăng ký push thất bại: $e'));
    }
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
