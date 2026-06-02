import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_session.dart';

/// Auth contract — implemented in data layer.
abstract interface class AuthRepository {
  Future<Result<AuthSession?>> restoreSession();

  Future<Result<AuthSession>> signInWithGoogle();

  Future<Result<AuthSession>> signInDev();

  Future<Result<AuthSession>> refreshSession();

  Future<Result<void>> signOut();
}
