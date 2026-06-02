import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/app_exception.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:snapstudy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:snapstudy/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_session.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_tokens.dart';
import 'package:snapstudy/features/auth/domain/entities/google_sign_in_result.dart';
import 'package:snapstudy/features/auth/domain/entities/user.dart';
import 'package:snapstudy/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
    required GoogleAuthDataSource googleAuthDataSource,
  })  : _local = localDataSource,
        _remote = remoteDataSource,
        _google = googleAuthDataSource;

  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;
  final GoogleAuthDataSource _google;

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    try {
      final session = await _local.readSession();
      if (session == null) return const Success(null);

      if (session.tokens.isExpired) {
        final refreshed = await refreshSession();
        if (refreshed.isSuccess && refreshed.valueOrNull != null) {
          return Success(refreshed.valueOrNull);
        }
        await _local.clearSession();
        return const Success(null);
      }

      return Success(session);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthSession>> signInWithGoogle() async {
    try {
      final googleResult = await _google.signIn();
      final session = await _resolveSession(googleResult);
      await _local.saveSession(session);
      return Success(session);
    } on AuthCancelledException catch (e) {
      return Error(e.toFailure()); // AuthCancelledFailure — không hiện snack
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthSession>> signInDev() async {
    if (!EnvConfig.authDevMode) {
      return const Error(
        ValidationFailure('Chế độ dev auth không được bật.'),
      );
    }

    const session = AuthSession(
      user: User(
        id: 'dev-user-001',
        email: 'dev@snapstudy.app',
        displayName: 'Dev Student',
      ),
      tokens: AuthTokens(
        accessToken: 'dev_access_token',
        refreshToken: 'dev_refresh_token',
        expiresAt: null,
      ),
    );

    await _local.saveSession(session);
    return const Success(session);
  }

  @override
  Future<Result<AuthSession>> refreshSession() async {
    try {
      final current = await _local.readSession();
      if (current == null) {
        return const Error(AuthFailure('Không có phiên để làm mới.'));
      }

      try {
        final dto = await _remote.refreshToken(current.tokens.refreshToken);
        final session = dto.toSession();
        await _local.saveSession(session);
        return Success(session);
      } on AppException catch (e) {
        if (EnvConfig.authDevMode &&
            current.tokens.accessToken.startsWith('dev_')) {
          return Success(current);
        }
        return Error(e.toFailure());
      }
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      try {
        await _remote.logout();
      } catch (e) {
        AppLogger.warning('Remote logout failed (ignored)', e);
      }
      await _google.signOut();
      await _local.clearSession();
      return const Success(null);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  Future<AuthSession> _resolveSession(GoogleSignInResult google) async {
    try {
      final dto = await _remote.exchangeGoogleToken(google.idToken);
      return dto.toSession();
    } on AppException catch (e) {
      if (!EnvConfig.authDevMode) rethrow;
      AppLogger.warning(
        'Backend JWT exchange failed — using dev session',
        e,
      );
      return _buildDevSession(google);
    }
  }

  AuthSession _buildDevSession(GoogleSignInResult google) {
    return AuthSession(
      user: User(
        id: google.googleUserId ?? 'google-${google.email.hashCode}',
        email: google.email,
        displayName: google.displayName,
        photoUrl: google.photoUrl,
      ),
      tokens: AuthTokens(
        accessToken: 'dev_${google.idToken.hashCode.abs()}',
        refreshToken: 'dev_refresh_${google.email.hashCode.abs()}',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ),
    );
  }
}
