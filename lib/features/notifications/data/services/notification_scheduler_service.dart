import 'package:snapstudy/core/notifications/notification_channels.dart';
import 'package:snapstudy/core/notifications/notification_ids.dart';
import 'package:snapstudy/core/notifications/notification_payload.dart';
import 'package:snapstudy/features/notifications/data/services/local_notification_service.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_preferences.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_sync_snapshot.dart';

/// Builds copy & schedules daily local reminders.
class NotificationSchedulerService {
  NotificationSchedulerService({required LocalNotificationService local})
      : _local = local;

  final LocalNotificationService _local;

  Future<void> sync({
    required NotificationPreferences prefs,
    required NotificationSyncSnapshot snapshot,
  }) async {
    await _local.cancel(NotificationIds.reviewDaily);
    await _local.cancel(NotificationIds.streakDaily);
    await _local.cancel(NotificationIds.sessionDaily);
    await _local.cancelCardReminders();

    if (prefs.reviewRemindersEnabled && snapshot.dueCards > 0) {
      final overdueLine = snapshot.overdueCards > 0
          ? ' · ${snapshot.overdueCards} quá hạn'
          : '';
      const title = 'Ôn tập SNAPSTUDY';
      final body =
          'Có ${snapshot.dueCards} thẻ cần ôn$overdueLine — giữ trí nhớ tốt hơn!';
      await _local.scheduleDaily(
        id: NotificationIds.reviewDaily,
        hour: prefs.reviewHour,
        minute: prefs.reviewMinute,
        title: title,
        body: body,
        channelId: NotificationChannels.review,
        payload: NotificationPayload.review,
      );
    }

    if (prefs.streakRemindersEnabled &&
        snapshot.streakDays > 0 &&
        snapshot.reviewedToday == 0) {
      final title = 'Giữ chuỗi ${snapshot.streakDays} ngày 🔥';
      const body = 'Bạn chưa ôn hôm nay — 5 phút SRS để không mất streak.';
      await _local.scheduleDaily(
        id: NotificationIds.streakDaily,
        hour: prefs.streakHour,
        minute: prefs.streakMinute,
        title: title,
        body: body,
        channelId: NotificationChannels.streak,
        payload: NotificationPayload.streak,
      );
    }

    if (prefs.sessionRemindersEnabled &&
        (snapshot.hasActiveSession || snapshot.pendingSessionCount > 0)) {
      final body = snapshot.hasActiveSession
          ? 'Buổi học đang mở — quay lại chụp thêm hoặc kết thúc để chạy AI.'
          : 'Có ${snapshot.pendingSessionCount} buổi chờ xử lý OCR/AI.';
      const title = 'Tiếp tục học với SNAPSTUDY';
      await _local.scheduleDaily(
        id: NotificationIds.sessionDaily,
        hour: prefs.sessionHour,
        minute: prefs.sessionMinute,
        title: title,
        body: body,
        channelId: NotificationChannels.session,
        payload: NotificationPayload.session,
      );
    }

    if (prefs.reviewRemindersEnabled) {
      final now = DateTime.now();
      final upcoming = snapshot.upcomingCardReminders
          .where((r) => r.reviewAt.isAfter(now))
          .take(24)
          .toList();

      for (final reminder in upcoming) {
        final preview = reminder.cardFront.length > 60
            ? '${reminder.cardFront.substring(0, 60)}…'
            : reminder.cardFront;
        await _local.scheduleAt(
          id: NotificationIds.cardReminderId(reminder.cardId),
          scheduledAt: reminder.reviewAt,
          title: 'Ôn thẻ · ${reminder.sessionTitle}',
          body: preview,
          channelId: NotificationChannels.review,
          payload: NotificationPayload.review,
        );
      }
    }
  }
}
