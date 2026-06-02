import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/lifecycle/study_session_lifecycle_handler.dart';
import 'package:snapstudy/core/notifications/notification_navigation.dart';
import 'package:snapstudy/core/routing/app_router.dart';
import 'package:snapstudy/features/notifications/presentation/providers/notification_providers.dart';
import 'package:snapstudy/core/startup/session_startup.dart';
import 'package:snapstudy/core/theme/app_theme.dart';
import 'package:snapstudy/core/theme/theme_mode_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';

/// Root widget — theme, router, and global app configuration.
class SnapStudyApp extends ConsumerStatefulWidget {
  const SnapStudyApp({super.key});

  @override
  ConsumerState<SnapStudyApp> createState() => _SnapStudyAppState();
}

class _SnapStudyAppState extends ConsumerState<SnapStudyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      final notifRepo = ref.read(notificationRepositoryProvider);
      NotificationNavigation.bind(
        router,
        onOpened: (payload) => notifRepo.handleNotificationOpened(payload),
      );
      unawaited(
        SessionStartup.normalizeActiveTimer(
          ref.read(sessionRepositoryProvider),
        ),
      );
      unawaited(ref.read(notificationBootstrapProvider.future));
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: EnvConfig.appName,
      debugShowCheckedModeBanner: EnvConfig.isDevelopment,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return StudySessionLifecycleHandler(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
