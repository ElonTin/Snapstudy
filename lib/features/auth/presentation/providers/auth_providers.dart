import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/di/providers.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:snapstudy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:snapstudy/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:snapstudy/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_session.dart';
import 'package:snapstudy/features/auth/domain/repositories/auth_repository.dart';
import 'package:snapstudy/features/auth/presentation/providers/onboarding_provider.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource(ref.watch(secureStorageProvider));
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(authDioProvider));
});

final googleAuthDataSourceProvider = Provider<GoogleAuthDataSource>((ref) {
  return GoogleAuthDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    localDataSource: ref.watch(authLocalDataSourceProvider),
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    googleAuthDataSource: ref.watch(googleAuthDataSourceProvider),
  );
});

/// Restores and manages the authenticated session.
class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final result = await ref.read(authRepositoryProvider).restoreSession();
    return result.fold(
      onSuccess: (session) {
        _syncToken(session);
        return session;
      },
      onFailure: (_) => null,
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    state = result.fold(
      onSuccess: (session) {
        _syncToken(session);
        return AsyncData(session);
      },
      onFailure: (f) {
        if (f is AuthCancelledFailure) {
          return const AsyncData(null);
        }
        return AsyncError(f, StackTrace.current);
      },
    );
  }

  Future<void> signInDev() async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signInDev();
    state = result.fold(
      onSuccess: (session) {
        _syncToken(session);
        return AsyncData(session);
      },
      onFailure: (f) => AsyncError(f, StackTrace.current),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).signOut();
    result.fold(
      onSuccess: (_) {
        _syncToken(null);
        state = const AsyncData(null);
      },
      onFailure: (f) {
        state = AsyncError(f, StackTrace.current);
      },
    );
  }

  void _syncToken(AuthSession? session) {
    ref.read(authTokenProvider.notifier).state =
        session?.tokens.accessToken;
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

final isAuthenticatedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth.maybeWhen(data: (s) => s != null, orElse: () => false);
});

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, _) => notifyListeners());
    _ref.listen(onboardingCompletedProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}
