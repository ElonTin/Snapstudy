import 'package:snapstudy/core/performance/performance_config.dart';
import 'package:snapstudy/core/performance/ttl_cache.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

/// Shared TTL cache for [SessionRepository.getAllSessions].
abstract final class SessionListCache {
  static TtlCache<List<StudySession>>? _cache;

  static TtlCache<List<StudySession>> get _ttl {
    return _cache ??= TtlCache<List<StudySession>>(
      ttl: PerformanceConfig.sessionListCacheTtl,
    );
  }

  static List<StudySession>? get() => _ttl.value;

  static void put(List<StudySession> sessions) => _ttl.put(sessions);

  static void invalidate() => _ttl.invalidate();
}
