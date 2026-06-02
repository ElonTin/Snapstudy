import 'package:snapstudy/core/cache/dashboard_cache.dart';
import 'package:snapstudy/core/cache/session_list_cache.dart';

/// Central invalidation for in-memory performance caches.
abstract final class PerformanceCaches {
  static void invalidateSessions() => SessionListCache.invalidate();

  static void invalidateDashboard() => DashboardCache.invalidate();

  static void invalidateAll() {
    invalidateSessions();
    invalidateDashboard();
  }
}
