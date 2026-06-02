/// Keys for [FlutterSecureStorage] — never store secrets in Hive.
abstract final class SecureStorageKeys {
  static const String accessToken = 'auth_access_token';
  static const String refreshToken = 'auth_refresh_token';
  static const String userJson = 'auth_user_json';
  static const String tokenExpiresAt = 'auth_token_expires_at';
}
