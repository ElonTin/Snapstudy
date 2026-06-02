import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/route_names.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/features/auth/presentation/pages/login_page.dart';
import 'package:snapstudy/features/auth/presentation/pages/onboarding_page.dart';
import 'package:snapstudy/features/auth/presentation/providers/auth_providers.dart';
import 'package:snapstudy/features/auth/presentation/providers/onboarding_provider.dart';
import 'package:snapstudy/features/home/presentation/pages/home_page.dart';
import 'package:snapstudy/features/notifications/presentation/pages/notification_history_page.dart';
import 'package:snapstudy/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:snapstudy/features/splash/presentation/pages/splash_page.dart';
import 'package:snapstudy/features/camera/presentation/pages/camera_capture_page.dart';
import 'package:snapstudy/features/sessions/presentation/pages/active_session_page.dart';
import 'package:snapstudy/features/flashcards/presentation/pages/flashcard_study_page.dart';
import 'package:snapstudy/features/mindmap/presentation/pages/mindmap_view_page.dart';
import 'package:snapstudy/features/quiz/presentation/pages/quiz_play_page.dart';
import 'package:snapstudy/features/spaced_repetition/presentation/pages/review_queue_page.dart';
import 'package:snapstudy/features/sessions/presentation/pages/session_detail_page.dart';
import 'package:snapstudy/features/sessions/presentation/pages/start_session_page.dart';
import 'package:snapstudy/features/subjects/presentation/pages/subject_form_page.dart';
import 'package:snapstudy/features/subjects/presentation/pages/subjects_list_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: EnvConfig.isDevelopment,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authAsync = ref.read(authControllerProvider);
      final onboardingDone = ref.read(onboardingCompletedProvider);
      final location = state.matchedLocation;

      final isLoading = authAsync.isLoading;
      final isAuthenticated =
          authAsync.maybeWhen(data: (s) => s != null, orElse: () => false);

      final isSplash = location == RoutePaths.splash;
      final isLogin = location == RoutePaths.login;
      final isOnboarding = location == RoutePaths.onboarding;
      final isPublicRoute = isSplash || isLogin || isOnboarding;

      // Giữ màn login khi đang xử lý Google Sign-In (tránh nhảy splash rồi quay lại login).
      if (isLoading && !isSplash && !isLogin) {
        return RoutePaths.splash;
      }

      if (!isLoading && !onboardingDone && !isOnboarding) {
        return RoutePaths.onboarding;
      }

      if (!isLoading && onboardingDone && !isAuthenticated && !isLogin) {
        return RoutePaths.login;
      }

      if (!isLoading && isAuthenticated && (isLogin || isOnboarding)) {
        return RoutePaths.home;
      }

      if (!isLoading && isAuthenticated && isSplash) {
        return RoutePaths.home;
      }

      if (!isLoading &&
          !isAuthenticated &&
          onboardingDone &&
          isSplash) {
        return RoutePaths.login;
      }

      if (!isLoading && !isAuthenticated && !isPublicRoute) {
        return RoutePaths.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RoutePaths.notificationSettings,
        name: RouteNames.notificationSettings,
        builder: (context, state) => const NotificationSettingsPage(),
        routes: [
          GoRoute(
            path: 'history',
            name: RouteNames.notificationHistory,
            builder: (context, state) => const NotificationHistoryPage(),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.reviewQueue,
        name: RouteNames.reviewQueue,
        builder: (context, state) => ReviewQueuePage(
          sessionId: state.uri.queryParameters['sessionId'],
        ),
      ),
      GoRoute(
        path: RoutePaths.subjects,
        name: RouteNames.subjects,
        builder: (context, state) => const SubjectsListPage(),
        routes: [
          GoRoute(
            path: 'new',
            name: RouteNames.subjectCreate,
            builder: (context, state) => const SubjectFormPage(),
          ),
          GoRoute(
            path: ':id/edit',
            name: RouteNames.subjectEdit,
            builder: (context, state) => SubjectFormPage(
              subjectId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.sessionStart,
        name: RouteNames.sessionStart,
        builder: (context, state) => StartSessionPage(
          preselectedSubjectId: state.uri.queryParameters['subjectId'],
        ),
      ),
      GoRoute(
        path: RoutePaths.sessionActive,
        name: RouteNames.sessionActive,
        builder: (context, state) => const ActiveSessionPage(),
      ),
      GoRoute(
        path: RoutePaths.cameraCapture,
        name: RouteNames.cameraCapture,
        builder: (context, state) {
          final colorRaw = state.uri.queryParameters['color'];
          Color? accent;
          if (colorRaw != null) {
            final parsed = int.tryParse(colorRaw);
            if (parsed != null) accent = Color(parsed);
          }
          return CameraCapturePage(accentColor: accent);
        },
      ),
      GoRoute(
        path: '/sessions/:id',
        name: RouteNames.sessionDetail,
        builder: (context, state) => SessionDetailPage(
          sessionId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'flashcards',
            name: RouteNames.flashcardStudy,
            builder: (context, state) => FlashcardStudyPage(
              sessionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'quiz',
            name: RouteNames.quizPlay,
            builder: (context, state) => QuizPlayPage(
              sessionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'mindmap',
            name: RouteNames.mindmapView,
            builder: (context, state) => MindmapViewPage(
              sessionId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Không tìm thấy trang: ${state.uri}'),
      ),
    ),
  );
});
