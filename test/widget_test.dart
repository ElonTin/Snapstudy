import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/theme/theme_mode_provider.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_session.dart';
import 'package:snapstudy/features/auth/presentation/pages/login_page.dart';
import 'package:snapstudy/features/auth/presentation/providers/auth_providers.dart';
import 'package:snapstudy/features/home/domain/entities/dashboard_data.dart';
import 'package:snapstudy/features/home/domain/entities/study_progress.dart';
import 'package:snapstudy/features/home/presentation/pages/home_page.dart';
import 'package:snapstudy/features/home/presentation/providers/dashboard_provider.dart';
import 'helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment(withHive: true);
  });

  testWidgets('Home shows greeting when session is provided',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _ImmediateAuthController(testAuthSession()),
          ),
          themeModeProvider.overrideWith(_FixedThemeMode.new),
          dashboardProvider.overrideWith(() => _ImmediateDashboard()),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Xin chào'), findsOneWidget);
    expect(find.text('Bắt đầu chụp'), findsOneWidget);
  });

  testWidgets('Login page shows sign-in actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _ImmediateAuthController(null),
          ),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Đăng nhập Dev (không cần Google)'), findsOneWidget);
  });
}

/// Synchronous auth state for widget tests.
class _ImmediateAuthController extends AuthController {
  _ImmediateAuthController(this._session);

  final AuthSession? _session;

  @override
  Future<AuthSession?> build() async => _session;
}

class _FixedThemeMode extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.light;
}

class _ImmediateDashboard extends DashboardController {
  @override
  Future<DashboardData> build() async => const DashboardData(
        progress: StudyProgress(
          sessionsThisWeek: 3,
          cardsReviewed: 10,
          studyMinutesToday: 20,
          streakDays: 2,
          weeklyGoalPercent: 0.5,
        ),
        subjects: [],
        recentSessions: [],
        aiActivities: [],
        upcomingReviews: [],
      );
}
