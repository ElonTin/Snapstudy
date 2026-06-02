import 'package:snapstudy/core/cache/dashboard_cache.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/performance/inflight_guard.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/home/data/datasources/dashboard_local_datasource.dart';
import 'package:snapstudy/features/home/domain/entities/dashboard_data.dart';
import 'package:snapstudy/features/home/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._local);

  final DashboardLocalDataSource _local;
  static final _inflight = InflightGuard();

  @override
  Future<Result<DashboardData>> fetchDashboard({bool force = false}) async {
    try {
      if (!force) {
        final cached = DashboardCache.get();
        if (cached != null) return Success(cached);
      }

      return _inflight.run('dashboard', () async {
        final data = await _local.fetchDashboard();
        DashboardCache.put(data);
        return Success(data);
      });
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
