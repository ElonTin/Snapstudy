/// HTTP API path segments and header keys.
abstract final class ApiConstants {
  static const String contentTypeJson = 'application/json';
  static const String acceptJson = 'application/json';

  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  // Auth endpoints (Phase 2)
  static const String authLogin = '/api/auth/login';
  static const String authRefresh = '/api/auth/refresh';
  static const String authGoogle = '/api/auth/google';
  static const String authLogout = '/api/auth/logout';

  // Health
  static const String health = '/api/health';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
