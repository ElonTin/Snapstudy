import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/cache/dashboard_cache.dart';
import 'package:snapstudy/core/cache/performance_caches.dart';
import 'package:snapstudy/core/cache/session_list_cache.dart';
import 'package:snapstudy/features/home/domain/entities/dashboard_data.dart';
import 'package:snapstudy/features/home/domain/entities/study_progress.dart';
import '../helpers/session_fixtures.dart';

void main() {
  setUp(PerformanceCaches.invalidateAll);

  test('invalidateAll clears session and dashboard caches', () {
    SessionListCache.put([testSessionWithOcr()]);
    DashboardCache.put(
      const DashboardData(
        progress: StudyProgress(
          sessionsThisWeek: 1,
          cardsReviewed: 0,
          studyMinutesToday: 0,
          streakDays: 0,
          weeklyGoalPercent: 0,
        ),
        subjects: [],
        recentSessions: [],
        aiActivities: [],
        upcomingReviews: [],
      ),
    );

    PerformanceCaches.invalidateAll();

    expect(SessionListCache.get(), isNull);
    expect(DashboardCache.get(), isNull);
  });
}
