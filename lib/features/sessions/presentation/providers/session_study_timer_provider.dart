import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/sessions/presentation/utils/session_formatters.dart';

/// Đếm thời gian học khi người dùng tương tác nội dung buổi học.
class SessionStudyTimerController extends Notifier<Duration> {
  String? _sessionId;
  Timer? _tickTimer;

  @override
  Duration build() => Duration.zero;

  Future<void> attach(String sessionId) async {
    if (_sessionId == sessionId) return;
    await detach();

    _sessionId = sessionId;
    await ref.read(sessionRepositoryProvider).beginStudyEngagement(sessionId);
    await _refreshElapsed();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshElapsed());
  }

  Future<void> detach() async {
    _tickTimer?.cancel();
    _tickTimer = null;
    final id = _sessionId;
    _sessionId = null;
    if (id != null) {
      await ref.read(sessionRepositoryProvider).endStudyEngagement(id);
      ref.invalidate(sessionDetailProvider(id));
    }
    state = Duration.zero;
  }

  Future<void> _refreshElapsed() async {
    final id = _sessionId;
    if (id == null) return;

    final result = await ref.read(sessionRepositoryProvider).getSessionById(id);
    final session = result.fold(onSuccess: (s) => s, onFailure: (_) => null);
    if (session != null) {
      state = session.elapsed;
    }
  }

  String get formatted => SessionFormatters.formatDuration(state);
}

final sessionStudyTimerProvider =
    NotifierProvider<SessionStudyTimerController, Duration>(
  SessionStudyTimerController.new,
);

/// Gắn / gỡ timer theo sessionId (dùng trong initState/dispose).
Future<void> bindSessionStudyTimer(WidgetRef ref, String sessionId) async {
  await ref.read(sessionStudyTimerProvider.notifier).attach(sessionId);
}

Future<void> unbindSessionStudyTimer(WidgetRef ref) async {
  await ref.read(sessionStudyTimerProvider.notifier).detach();
}
