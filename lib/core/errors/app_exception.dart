import 'package:snapstudy/core/errors/failures.dart';

/// Data/presentation layer exceptions mapped to [Failure].
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  Failure toFailure();
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']);

  @override
  Failure toFailure() => NetworkFailure(message);
}

final class ServerException extends AppException {
  const ServerException([super.message = 'Server error']);

  @override
  Failure toFailure() => ServerFailure(message);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized']);

  @override
  Failure toFailure() => AuthFailure(message);
}

final class CacheException extends AppException {
  const CacheException([super.message = 'Cache error']);

  @override
  Failure toFailure() => CacheFailure(message);
}

final class AuthCancelledException extends AppException {
  const AuthCancelledException([
    super.message = 'Đăng nhập Google đã bị hủy.',
  ]);

  @override
  Failure toFailure() => const AuthCancelledFailure();
}
