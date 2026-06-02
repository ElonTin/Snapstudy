import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';

/// Lightweight tasks after UI is up — avoids blocking [bootstrap].
abstract final class SessionStartup {
  static Future<void> normalizeActiveTimer(SessionRepository sessions) async {
    final active = await sessions.getActiveSession();
    final session = active.fold(onSuccess: (s) => s, onFailure: (_) => null);
    if (session == null || !session.isActive) return;

    if (session.isTimerRunning) {
      final paused = await sessions.pauseActiveSessionTimer();
      paused.fold(
        onSuccess: (_) =>
            AppLogger.info('Paused stale active-session timer on startup'),
        onFailure: (_) {},
      );
    }
  }
}
