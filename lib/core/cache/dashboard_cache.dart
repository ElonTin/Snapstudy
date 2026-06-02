import 'package:snapstudy/core/performance/performance_config.dart';
import 'package:snapstudy/core/performance/ttl_cache.dart';
import 'package:snapstudy/features/home/domain/entities/dashboard_data.dart';

abstract final class DashboardCache {
  static TtlCache<DashboardData>? _cache;

  static TtlCache<DashboardData> get _ttl {
    return _cache ??= TtlCache<DashboardData>(
      ttl: PerformanceConfig.dashboardCacheTtl,
    );
  }

  static DashboardData? get() => _ttl.value;

  static void put(DashboardData data) => _ttl.put(data);

  static void invalidate() => _ttl.invalidate();
}
