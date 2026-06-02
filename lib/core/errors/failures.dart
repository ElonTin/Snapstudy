import 'package:equatable/equatable.dart';

/// Domain-layer failure representation (UI maps these to messages).
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Không có kết nối mạng. Vui lòng thử lại.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Lỗi máy chủ. Vui lòng thử lại sau.']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Lỗi lưu trữ cục bộ.']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Phiên đăng nhập không hợp lệ.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// User closed the Google account picker — not an error.
final class AuthCancelledFailure extends Failure {
  const AuthCancelledFailure([
    super.message = 'Đăng nhập Google đã bị hủy.',
  ]);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Đã xảy ra lỗi không xác định.']);
}
