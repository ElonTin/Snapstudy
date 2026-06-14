import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/firebase/firebase_service.dart';
import 'package:snapstudy/features/auth/presentation/providers/auth_providers.dart';
import 'package:snapstudy/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:snapstudy/features/notifications/data/services/fcm_service.dart';
import 'package:snapstudy/features/notifications/data/services/local_notification_service.dart';
import 'package:snapstudy/features/notifications/data/services/notification_history_service.dart';
import 'package:snapstudy/features/notifications/data/services/push_registration_api.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_preferences.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_record.dart';
import 'package:snapstudy/features/notifications/domain/repositories/notification_repository.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/spaced_repetition/presentation/providers/spaced_repetition_providers.dart';

final notificationHistoryServiceProvider =
    Provider<NotificationHistoryService>((ref) {
  return NotificationHistoryService();
});

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => LocalNotificationService(),
);

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final local = ref.watch(localNotificationServiceProvider);
  final history = ref.watch(notificationHistoryServiceProvider);

  return NotificationRepositoryImpl(
    sessions: ref.watch(sessionRepositoryProvider),
    spacedRepetition: ref.watch(spacedRepetitionRepositoryProvider),
    local: local,
    history: history,
    fcm: FcmService(
      local: local,
      history: history,
      pushApi: PushRegistrationApi(),
      resolveAuthBearer: () async {
        final session = ref.read(authControllerProvider).valueOrNull;
        return session?.tokens.accessToken;
      },
      resolveUserId: () async {
        final session = ref.read(authControllerProvider).valueOrNull;
        return session?.user.id;
      },
    ),
  );
});

final notificationPreferencesProvider =
    FutureProvider<NotificationPreferences>((ref) async {
  final result =
      await ref.read(notificationRepositoryProvider).getPreferences();
  return result.fold(
    onSuccess: (p) => p,
    onFailure: (f) => throw f,
  );
});

final notificationHistoryProvider =
    FutureProvider<List<NotificationRecord>>((ref) async {
  final result =
      await ref.read(notificationRepositoryProvider).getHistory();
  return result.fold(
    onSuccess: (list) => list,
    onFailure: (f) => throw f,
  );
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final result =
      await ref.read(notificationRepositoryProvider).getUnreadCount();
  return result.fold(
    onSuccess: (c) => c,
    onFailure: (_) => 0,
  );
});

/// Re-registers FCM token when user signs in (userId on server).
final pushRegistrationSyncProvider = Provider<void>((ref) {
  ref.listen(authControllerProvider, (previous, next) {
    final session = next.valueOrNull;
    if (session == null) return;
    final prevId = previous?.valueOrNull?.user.id;
    if (prevId == session.user.id) return;
    unawaited(
      ref.read(notificationRepositoryProvider).registerPushWithServer(),
    );
  });
});

/// Initializes notifications and syncs daily schedules.
final notificationBootstrapProvider = FutureProvider<void>((ref) async {
  await FirebaseService.ensureInitialized();
  final repo = ref.read(notificationRepositoryProvider);
  await repo.initialize();
  final prefs = await repo.getPreferences();
  final preferences = prefs.fold(
    onSuccess: (p) => p,
    onFailure: (_) => const NotificationPreferences(),
  );
  if (!preferences.permissionAsked) {
    await repo.requestPermission();
  }
  await repo.syncScheduledReminders();
  await repo.registerPushWithServer();
});

/// Call after SRS review or session changes.
Future<void> syncAppNotifications(Ref ref) async {
  await ref.read(notificationRepositoryProvider).syncScheduledReminders();
}
