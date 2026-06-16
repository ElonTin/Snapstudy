import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/app_exception.dart';
import 'package:snapstudy/core/firebase/firebase_service.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/features/auth/domain/entities/google_sign_in_result.dart';

/// Google Sign-In + optional Firebase credential exchange.
class GoogleAuthDataSource {
  GoogleAuthDataSource({
    GoogleSignIn? googleSignIn,
    firebase_auth.FirebaseAuth? firebaseAuth,
  })  : _googleSignIn = googleSignIn ?? _createGoogleSignIn(),
        _firebaseAuth = firebaseAuth;

  final GoogleSignIn _googleSignIn;
  final firebase_auth.FirebaseAuth? _firebaseAuth;

  static GoogleSignIn _createGoogleSignIn() {
    final serverClientId = EnvConfig.googleServerClientId;
    return GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: serverClientId,
      serverClientId: serverClientId,
    );
  }

  Future<GoogleSignInResult> signIn() async {
    final serverClientId = EnvConfig.googleServerClientId;
    if (serverClientId == null || serverClientId.isEmpty) {
      throw const NetworkException(
        'Thiếu GOOGLE_SERVER_CLIENT_ID (OAuth Web client) trong .env. '
        'Sau đó chạy lại: flutter run',
      );
    }

    try {
      // Tránh phiên Google cũ gây lỗi sau khi đổi SHA-1 / client ID.
      await _googleSignIn.signOut();

      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const AuthCancelledException();
      }

      final googleAuth = await account.authentication;
      var idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const NetworkException(
          'Không lấy được Google ID token. Trên Android cần:\n'
          '• GOOGLE_SERVER_CLIENT_ID = OAuth client loại Web\n'
          '• SHA-1 debug trong Google Cloud / Firebase (chạy: cd android && gradlew signingReport)',
        );
      }

      if (FirebaseService.isInitialized) {
        final auth = _firebaseAuth ?? firebase_auth.FirebaseAuth.instance;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: idToken,
        );
        final userCredential = await auth.signInWithCredential(credential);
        final firebaseToken = await userCredential.user?.getIdToken();
        if (firebaseToken != null && firebaseToken.isNotEmpty) {
          idToken = firebaseToken;
        }
      }

      final email = account.email;
      if (email.isEmpty) {
        throw const NetworkException(
          'Tài khoản Google không có email — hãy chọn tài khoản khác.',
        );
      }

      return GoogleSignInResult(
        idToken: idToken,
        email: email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        googleUserId: account.id,
      );
    } on AppException {
      rethrow;
    } on PlatformException catch (e, st) {
      AppLogger.error('Google sign-in platform error', e, st);
      throw NetworkException(_mapPlatformError(e));
    } catch (e, st) {
      AppLogger.error('Google sign-in failed', e, st);
      throw NetworkException(_mapGenericError(e));
    }
  }

  static String _mapPlatformError(PlatformException e) {
    final code = '${e.code} ${e.message}';
    if (code.contains('10') || code.contains('DEVELOPER_ERROR')) {
      return 'Cấu hình Google Sign-In sai (lỗi 10): thêm SHA-1 + package '
          'com.snapstudy.snapstudy vào OAuth Android trong Google Cloud Console.';
    }
    if (code.contains('1250') || code.contains('12500')) {
      return 'Google Play Services lỗi — cập nhật Play Services hoặc thử lại.';
    }
    if (code.contains('sign_in_canceled') || code.contains('canceled')) {
      return 'Đăng nhập Google đã bị hủy.';
    }
    return 'Đăng nhập Google thất bại ($code).';
  }

  static String _mapGenericError(Object e) {
    final text = e.toString();
    if (text.contains('ApiException: 10') || text.contains('DEVELOPER_ERROR')) {
      return 'Cấu hình Google Sign-In sai: kiểm tra SHA-1 và OAuth Android client.';
    }
    return 'Đăng nhập Google thất bại: $e';
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (FirebaseService.isInitialized) {
        final auth = _firebaseAuth ?? firebase_auth.FirebaseAuth.instance;
        await auth.signOut();
      }
    } catch (e) {
      AppLogger.warning('Google sign-out warning', e);
    }
  }
}
