import 'package:dio/dio.dart';
import 'package:snapstudy/core/constants/api_constants.dart';
import 'package:snapstudy/core/network/api_exception_mapper.dart';
import 'package:snapstudy/features/auth/data/models/auth_response_dto.dart';

/// Backend auth API — JWT exchange and refresh.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthResponseDto> exchangeGoogleToken(String idToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.authGoogle,
        data: {'idToken': idToken},
      );
      return AuthResponseDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<AuthResponseDto> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.authRefresh,
        data: {'refreshToken': refreshToken},
      );
      return AuthResponseDto.fromJson(response.data ?? {});
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiConstants.authLogout);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return;
      throw mapDioException(e);
    }
  }
}
