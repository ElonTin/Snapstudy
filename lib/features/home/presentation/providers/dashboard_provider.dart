import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/cache/dashboard_cache.dart';
import 'package:snapstudy/features/home/data/datasources/dashboard_local_datasource.dart';
import 'package:snapstudy/features/home/data/repositories/dashboard_repository_impl.dart';
import 'package:snapstudy/features/home/domain/entities/dashboard_data.dart';
import 'package:snapstudy/features/home/domain/repositories/dashboard_repository.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/spaced_repetition/presentation/providers/spaced_repetition_providers.dart';
import 'package:snapstudy/features/subjects/presentation/providers/subject_providers.dart';

final dashboardLocalDataSourceProvider = Provider<DashboardLocalDataSource>(
  (ref) => DashboardLocalDataSource(
    ref.watch(subjectRepositoryProvider),
    ref.watch(sessionRepositoryProvider),
    ref.watch(spacedRepetitionRepositoryProvider),
  ),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardLocalDataSourceProvider));
});

class DashboardController extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    final result = await ref.read(dashboardRepositoryProvider).fetchDashboard();
    return result.fold(
      onSuccess: (data) => data,
      onFailure: (f) => throw f,
    );
  }

  Future<void> refresh() async {
    DashboardCache.invalidate();
    state = const AsyncLoading<DashboardData>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(dashboardRepositoryProvider)
          .fetchDashboard(force: true);
      return result.fold(
        onSuccess: (data) => data,
        onFailure: (f) => throw f,
      );
    });
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardController, DashboardData>(
  DashboardController.new,
);
