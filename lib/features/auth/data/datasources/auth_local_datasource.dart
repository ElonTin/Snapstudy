import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:snapstudy/core/errors/app_exception.dart';
import 'package:snapstudy/core/storage/secure_storage_keys.dart';
import 'package:snapstudy/features/auth/data/models/user_dto.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_session.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_tokens.dart';

/// Persists auth session in encrypted secure storage.
class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  final FlutterSecureStorage _storage;

  Future<AuthSession?> readSession() async {
    try {
      final accessToken =
          await _storage.read(key: SecureStorageKeys.accessToken);
      final refreshToken =
          await _storage.read(key: SecureStorageKeys.refreshToken);
      final userJson = await _storage.read(key: SecureStorageKeys.userJson);
      final expiresAtStr =
          await _storage.read(key: SecureStorageKeys.tokenExpiresAt);

      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          userJson == null) {
        return null;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = UserDto.fromJson(userMap).toEntity();
      final expiresAt = expiresAtStr != null
          ? DateTime.tryParse(expiresAtStr)
          : null;

      return AuthSession(
        user: user,
        tokens: AuthTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAt,
        ),
      );
    } catch (e) {
      throw CacheException('Không đọc được phiên đăng nhập: $e');
    }
  }

  Future<void> saveSession(AuthSession session) async {
    try {
      await _storage.write(
        key: SecureStorageKeys.accessToken,
        value: session.tokens.accessToken,
      );
      await _storage.write(
        key: SecureStorageKeys.refreshToken,
        value: session.tokens.refreshToken,
      );
      await _storage.write(
        key: SecureStorageKeys.userJson,
        value: jsonEncode(UserDto.fromEntity(session.user).toJson()),
      );
      if (session.tokens.expiresAt != null) {
        await _storage.write(
          key: SecureStorageKeys.tokenExpiresAt,
          value: session.tokens.expiresAt!.toIso8601String(),
        );
      }
    } catch (e) {
      throw CacheException('Không lưu được phiên đăng nhập: $e');
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: SecureStorageKeys.accessToken);
    await _storage.delete(key: SecureStorageKeys.refreshToken);
    await _storage.delete(key: SecureStorageKeys.userJson);
    await _storage.delete(key: SecureStorageKeys.tokenExpiresAt);
  }
}
