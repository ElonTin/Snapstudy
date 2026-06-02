import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:snapstudy/core/network/dio_client.dart';

/// Global dependency injection via Riverpod.

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

/// JWT access token — synced by [AuthController].
final authTokenProvider = StateProvider<String?>((ref) => null);

/// Dio for auth API calls only (no token-refresh interceptor).
final authDioProvider = Provider<Dio>((ref) => createBaseDio());

/// Main API client with interceptors.
final dioProvider = Provider<Dio>((ref) => createDioClient(ref));
