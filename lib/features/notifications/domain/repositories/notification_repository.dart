import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_preferences.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_record.dart';

abstract interface class NotificationRepository {
  Future<Result<void>> initialize();

  Future<Result<bool>> requestPermission();

  Future<Result<NotificationPreferences>> getPreferences();

  Future<Result<NotificationPreferences>> savePreferences(
    NotificationPreferences prefs,
  );

  /// Re-schedules daily local reminders from current app state.
  Future<Result<void>> syncScheduledReminders();

  Future<Result<void>> showInstantReviewReminder({
    required int dueCount,
    required int overdueCount,
  });

  Future<Result<List<NotificationRecord>>> getHistory();

  Future<Result<int>> getUnreadCount();

  Future<Result<void>> markHistoryRead(String id);

  Future<Result<void>> markAllHistoryRead();

  Future<Result<void>> deleteHistoryItem(String id);

  Future<Result<void>> clearHistory();

  Future<Result<void>> registerPushWithServer();

  Future<Result<void>> handleNotificationOpened(String? payload);
}
