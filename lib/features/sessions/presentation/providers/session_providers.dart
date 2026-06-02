import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/home/presentation/providers/dashboard_provider.dart';
import 'package:snapstudy/features/notifications/presentation/providers/notification_providers.dart';
import 'package:snapstudy/features/camera/presentation/providers/camera_providers.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

final sessionLocalDataSourceProvider = Provider<SessionLocalDataSource>(
  (ref) => SessionLocalDataSource(),
);

final sessionFileStorageProvider = Provider<SessionFileStorage>(
  (ref) => SessionFileStorage(),
);

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(
    local: ref.watch(sessionLocalDataSourceProvider),
    fileStorage: ref.watch(sessionFileStorageProvider),
  );
});

/// Fast check for home / capture — does not start the session timer.
final hasActiveSessionProvider = Provider<bool>((ref) {
  final id = ref.watch(sessionLocalDataSourceProvider).readActiveSessionId();
  return id != null;
});

/// Banner / home summary — one Hive read, no [Timer.periodic].
final activeSessionPreviewProvider =
    FutureProvider.autoDispose<ActiveSessionPreview?>((ref) async {
  final id = ref.watch(sessionLocalDataSourceProvider).readActiveSessionId();
  if (id == null) return null;

  final result = await ref.read(sessionRepositoryProvider).getSessionById(id);
  final session = result.fold(onSuccess: (s) => s, onFailure: (_) => null);
  if (session == null || !session.isActive) return null;

  return ActiveSessionPreview(
    session: session,
    elapsed: session.elapsed,
  );
});

class ActiveSessionPreview {
  const ActiveSessionPreview({
    required this.session,
    required this.elapsed,
  });

  final StudySession session;
  final Duration elapsed;
}

/// Active session + live timer (only on active session screen).
class ActiveSessionState {
  const ActiveSessionState({this.session, this.elapsed = Duration.zero});

  final StudySession? session;
  final Duration elapsed;

  bool get hasActive => session != null && session!.isActive;
}

class ActiveSessionController extends AsyncNotifier<ActiveSessionState> {
  Timer? _uiTimer;

  @override
  Future<ActiveSessionState> build() async {
    ref.onDispose(_stopUiTimer);

    final result = await ref.read(sessionRepositoryProvider).getActiveSession();
    final session = result.fold(
      onSuccess: (s) => s,
      onFailure: (_) => null,
    );

    if (session != null && session.isActive) {
      return ActiveSessionState(session: session, elapsed: session.elapsed);
    }
    return const ActiveSessionState();
  }

  void _startUiTimer() {
    _stopUiTimer();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.valueOrNull?.session;
      if (current == null || !current.isTimerRunning) {
        _stopUiTimer();
        return;
      }
      state = AsyncData(
        ActiveSessionState(session: current, elapsed: current.elapsed),
      );
    });
  }

  void _stopUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = null;
  }

  void _applySession(StudySession? session) {
    if (session != null && session.isActive) {
      state = AsyncData(
        ActiveSessionState(session: session, elapsed: session.elapsed),
      );
      if (session.isTimerRunning) {
        _startUiTimer();
      } else {
        _stopUiTimer();
      }
    } else {
      _stopUiTimer();
      state = const AsyncData(ActiveSessionState());
    }
    ref.invalidate(activeSessionPreviewProvider);
  }

  Future<void> refresh() async {
    final result =
        await ref.read(sessionRepositoryProvider).getActiveSession();
    final session = result.fold(onSuccess: (s) => s, onFailure: (_) => null);
    _applySession(session);
  }

  Future<void> pauseTimer() async {
    _stopUiTimer();
    final result =
        await ref.read(sessionRepositoryProvider).pauseActiveSessionTimer();
    result.fold(
      onSuccess: _applySession,
      onFailure: (_) {},
    );
  }

  Future<void> resumeTimer() async {
    final result =
        await ref.read(sessionRepositoryProvider).resumeActiveSessionTimer();
    result.fold(
      onSuccess: _applySession,
      onFailure: (_) {},
    );
  }

  Future<StudySession?> startSession({
    required Subject subject,
    required String title,
    String? notes,
  }) async {
    final result = await ref.read(sessionRepositoryProvider).startSession(
          subject: subject,
          title: title,
          notes: notes,
        );
    return result.fold(
      onSuccess: (session) async {
        _applySession(session);
        ref.invalidate(dashboardProvider);
        return session;
      },
      onFailure: (f) {
        state = AsyncError(f, StackTrace.current);
        return null;
      },
    );
  }

  Future<bool> addCapture(String imagePath, {bool processImage = false}) async {
    final sessionId = state.valueOrNull?.session?.id;
    if (sessionId == null) return false;

    var path = imagePath;
    if (processImage) {
      path = await ref
          .read(captureProcessingServiceProvider)
          .processCapture(imagePath);
    }

    final result = await ref.read(sessionRepositoryProvider).addCaptureToQueue(
          sessionId: sessionId,
          imagePath: path,
        );

    if (result.isSuccess) {
      _applySession(result.valueOrNull);
      return true;
    }
    return false;
  }

  Future<int> addCaptures(
    List<String> imagePaths, {
    bool processImages = false,
  }) async {
    var added = 0;
    for (final path in imagePaths) {
      if (await addCapture(path, processImage: processImages)) added++;
    }
    return added;
  }

  Future<bool> removeCapture(String itemId) async {
    final sessionId = state.valueOrNull?.session?.id;
    if (sessionId == null) return false;

    final result = await ref.read(sessionRepositoryProvider).removeFromQueue(
          sessionId: sessionId,
          itemId: itemId,
        );
    if (result.isSuccess) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<StudySession?> endSession() async {
    final sessionId = state.valueOrNull?.session?.id;
    if (sessionId == null) return null;

    await pauseTimer();
    final result =
        await ref.read(sessionRepositoryProvider).endSession(sessionId);
    return result.fold(
      onSuccess: (session) async {
        state = const AsyncData(ActiveSessionState());
        ref.invalidate(activeSessionPreviewProvider);
        ref.invalidate(dashboardProvider);
        unawaited(syncAppNotifications(ref));
        return session;
      },
      onFailure: (f) {
        state = AsyncError(f, StackTrace.current);
        return null;
      },
    );
  }

  Future<bool> cancelSession() async {
    final sessionId = state.valueOrNull?.session?.id;
    if (sessionId == null) return false;

    await pauseTimer();
    final result =
        await ref.read(sessionRepositoryProvider).cancelSession(sessionId);
    if (result.isSuccess) {
      state = const AsyncData(ActiveSessionState());
      ref.invalidate(activeSessionPreviewProvider);
      ref.invalidate(dashboardProvider);
      return true;
    }
    return false;
  }
}

final activeSessionProvider =
    AsyncNotifierProvider<ActiveSessionController, ActiveSessionState>(
  ActiveSessionController.new,
);

/// Session detail — autoDispose, replaces [FutureBuilder] reload pattern.
final sessionDetailProvider =
    FutureProvider.autoDispose.family<StudySession?, String>(
  (ref, sessionId) async {
    final result =
        await ref.watch(sessionRepositoryProvider).getSessionById(sessionId);
    return result.fold(onSuccess: (s) => s, onFailure: (_) => null);
  },
);
