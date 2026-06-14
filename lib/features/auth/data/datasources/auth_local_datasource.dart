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
      return await _readRawSession();
    } catch (e) {
      // Tự động sửa lỗi: Nếu khóa KeyStore bị lỗi (do Android Auto Backup khôi phục file cũ nhưng mất khóa)
      // ta tiến hành xóa sạch dữ liệu cũ để tránh crash ứng dụng.
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  Future<AuthSession?> _readRawSession() async {
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
  }

  Future<void> saveSession(AuthSession session) async {
    try {
      await _writeRawSession(session);
    } catch (e) {
      // Nếu ghi thất bại do KeyStore lỗi, xóa toàn bộ và ghi lại lần nữa
      try {
        await _storage.deleteAll();
        await _writeRawSession(session);
      } catch (retryError) {
        throw CacheException('Không lưu được phiên đăng nhập: $retryError');
      }
    }
  }

  Future<void> _writeRawSession(AuthSession session) async {
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
  }

  Future<void> clearSession() async {
    await _storage.delete(key: SecureStorageKeys.accessToken);
    await _storage.delete(key: SecureStorageKeys.refreshToken);
    await _storage.delete(key: SecureStorageKeys.userJson);
    await _storage.delete(key: SecureStorageKeys.tokenExpiresAt);
  }
}
