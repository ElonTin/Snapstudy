import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/home/domain/entities/dashboard_data.dart';

abstract interface class DashboardRepository {
  Future<Result<DashboardData>> fetchDashboard({bool force = false});
}
