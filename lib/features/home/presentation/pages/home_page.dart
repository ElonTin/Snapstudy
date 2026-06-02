import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/theme_mode_provider.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_error_view.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/cached_network_avatar.dart';
import 'package:snapstudy/features/auth/presentation/providers/auth_providers.dart';
import 'package:snapstudy/features/home/domain/entities/study_progress.dart';
import 'package:snapstudy/features/home/presentation/providers/dashboard_provider.dart';
import 'package:snapstudy/features/camera/presentation/utils/camera_navigation.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/active_session_banner.dart';
import 'package:snapstudy/features/home/presentation/widgets/ai_activity_section.dart';
import 'package:snapstudy/features/home/presentation/widgets/dashboard_fade_in.dart';
import 'package:snapstudy/features/home/presentation/widgets/dashboard_header.dart';
import 'package:snapstudy/features/home/presentation/widgets/progress_stats_row.dart';
import 'package:snapstudy/features/home/presentation/widgets/quick_capture_card.dart';
import 'package:snapstudy/features/home/presentation/widgets/recent_sessions_section.dart';
import 'package:snapstudy/features/home/presentation/widgets/review_reminder_banner.dart';
import 'package:snapstudy/features/home/presentation/widgets/subject_cards_section.dart';
import 'package:snapstudy/features/home/presentation/widgets/upcoming_reviews_section.dart';
import 'package:snapstudy/features/notifications/presentation/providers/notification_providers.dart';

/// Student dashboard — Phase 3.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const SafeArea(child: _HomeDashboardBody()),
      floatingActionButton: const _HomeCaptureFab(),
    );
  }
}

/// Chỉ rebuild khi dashboard / active session thay đổi.
class _HomeDashboardBody extends ConsumerWidget {
  const _HomeDashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return dashboard.when(
      loading: () => const AppLoading(
        fullScreen: true,
        message: 'Đang tải bảng điều khiển...',
      ),
      error: (e, _) => AppErrorView(
        message: e.toString(),
        onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.defaultPadding,
                  8,
                  AppConstants.defaultPadding,
                  0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _HomeTopBar(),
                        const SizedBox(height: 20),
                        DashboardFadeIn(
                          child: _HomeGreetingHeader(progress: data.progress),
                        ),
                        const SizedBox(height: 20),
                        DashboardFadeIn(
                          delay: const Duration(milliseconds: 50),
                          child: ProgressStatsRow(progress: data.progress),
                        ),
                        const SizedBox(height: 16),
                        const ReviewReminderBanner(),
                        const ActiveSessionBanner(),
                        DashboardFadeIn(
                          delay: const Duration(milliseconds: 100),
                          child: _HomeQuickCapture(),
                        ),
                        const SizedBox(height: 28),
                        DashboardFadeIn(
                          delay: const Duration(milliseconds: 150),
                          child: SubjectCardsSection(subjects: data.subjects),
                        ),
                        const SizedBox(height: 28),
                        DashboardFadeIn(
                          delay: const Duration(milliseconds: 200),
                          child: RecentSessionsSection(
                            sessions: data.recentSessions,
                          ),
                        ),
                        const SizedBox(height: 28),
                        DashboardFadeIn(
                          delay: const Duration(milliseconds: 250),
                          child: AiActivitySection(
                            activities: data.aiActivities,
                          ),
                        ),
                        const SizedBox(height: 28),
                        DashboardFadeIn(
                          delay: const Duration(milliseconds: 300),
                          child: UpcomingReviewsSection(
                            reviews: data.upcomingReviews,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeGreetingHeader extends ConsumerWidget {
  const _HomeGreetingHeader({required this.progress});

  final StudyProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(
      authControllerProvider.select(
        (a) => a.valueOrNull?.user.displayName ?? 'Học sinh',
      ),
    );
    return DashboardHeader(userName: name, progress: progress);
  }
}

class _HomeQuickCapture extends ConsumerWidget {
  const _HomeQuickCapture();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return QuickCaptureCard(onCapture: () => _openCapture(context, ref));
  }
}

Future<void> _openCapture(BuildContext context, WidgetRef ref) async {
  final hasActive = ref.read(hasActiveSessionProvider);
  if (hasActive) {
    final session = ref.read(activeSessionProvider).valueOrNull?.session;
    final paths = await openCameraCapture(
      context,
      accentColor:
          session != null ? Color(session.subjectColorValue) : null,
    );
    if (paths != null && paths.isNotEmpty && context.mounted) {
      final added =
          await ref.read(activeSessionProvider.notifier).addCaptures(paths);
      if (context.mounted) {
        context.showSnack(
          added > 0 ? 'Đã thêm $added ảnh' : 'Không thêm được ảnh',
          isError: added == 0,
        );
      }
    }
  } else {
    context.push(RoutePaths.sessionStart);
  }
}

class _HomeCaptureFab extends ConsumerWidget {
  const _HomeCaptureFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActive = ref.watch(hasActiveSessionProvider);
    final showFab = ref.watch(
      dashboardProvider.select((d) => d.hasValue && !d.hasError),
    );
    if (!showFab) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => _openCapture(context, ref),
      icon: const Icon(Icons.camera_alt_rounded),
      label: Text(hasActive ? 'Tiếp tục' : 'Chụp'),
    );
  }
}

class _HomeTopBar extends ConsumerWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
        ),
        const Spacer(),
        Consumer(
          builder: (context, ref, _) {
            final count = ref.watch(
              unreadNotificationCountProvider.select(
                (a) => a.valueOrNull ?? 0,
              ),
            );
            return Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(RoutePaths.notificationHistory),
                tooltip: 'Hộp thông báo',
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push(RoutePaths.notificationSettings),
          tooltip: 'Cài đặt thông báo',
        ),
        IconButton(
          icon: Icon(
            themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: () {
            final next = themeMode == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.dark;
            ref.read(themeModeProvider.notifier).setThemeMode(next);
          },
          tooltip: 'Đổi giao diện',
        ),
        PopupMenuButton<String>(
          icon: CachedNetworkAvatar(
            radius: 18,
            photoUrl: auth?.user.photoUrl,
            initials: auth?.user.initials ?? '?',
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
          ),
          onSelected: (value) {
            if (value == 'logout') {
              ref.read(authControllerProvider.notifier).signOut();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth?.user.displayName ?? 'Học sinh',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    auth?.user.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text('Đăng xuất'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
