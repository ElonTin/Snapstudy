import 'package:dio/dio.dart';
import 'package:snapstudy/core/errors/app_exception.dart';

/// Maps Dio errors to typed [AppException].
AppException mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException('Kết nối quá thời gian chờ.');
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;
      final message = _extractMessage(error.response?.data);
      if (status == 401 || status == 403) {
        return UnauthorizedException(message);
      }
      if (status != null && status >= 500) {
        return ServerException(message);
      }
      return ServerException(message);
    case DioExceptionType.cancel:
      return const NetworkException('Yêu cầu đã bị hủy.');
    default:
      return NetworkException(error.message ?? 'Lỗi mạng.');
  }
}

String _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    return (data['message'] ?? data['title'] ?? 'Lỗi máy chủ').toString();
  }
  return 'Lỗi máy chủ';
}
