import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_preferences.dart';

class NotificationPrefsDataSource {
  NotificationPreferences read() {
    final box = HiveService.settingsBox;
    return NotificationPreferences(
      reviewRemindersEnabled:
          box.get(StorageKeys.notifReviewEnabled, defaultValue: true) as bool,
      streakRemindersEnabled:
          box.get(StorageKeys.notifStreakEnabled, defaultValue: true) as bool,
      sessionRemindersEnabled:
          box.get(StorageKeys.notifSessionEnabled, defaultValue: true) as bool,
      reviewHour: box.get(StorageKeys.notifReviewHour, defaultValue: 19) as int,
      reviewMinute:
          box.get(StorageKeys.notifReviewMinute, defaultValue: 0) as int,
      streakHour: box.get(StorageKeys.notifStreakHour, defaultValue: 8) as int,
      streakMinute:
          box.get(StorageKeys.notifStreakMinute, defaultValue: 30) as int,
      sessionHour:
          box.get(StorageKeys.notifSessionHour, defaultValue: 17) as int,
      sessionMinute:
          box.get(StorageKeys.notifSessionMinute, defaultValue: 0) as int,
      permissionAsked:
          box.get(StorageKeys.notifPermissionAsked, defaultValue: false)
              as bool,
      fcmToken: box.get(StorageKeys.notifFcmToken) as String?,
    );
  }

  Future<void> write(NotificationPreferences prefs) async {
    final box = HiveService.settingsBox;
    await box.put(
      StorageKeys.notifReviewEnabled,
      prefs.reviewRemindersEnabled,
    );
    await box.put(
      StorageKeys.notifStreakEnabled,
      prefs.streakRemindersEnabled,
    );
    await box.put(
      StorageKeys.notifSessionEnabled,
      prefs.sessionRemindersEnabled,
    );
    await box.put(StorageKeys.notifReviewHour, prefs.reviewHour);
    await box.put(StorageKeys.notifReviewMinute, prefs.reviewMinute);
    await box.put(StorageKeys.notifStreakHour, prefs.streakHour);
    await box.put(StorageKeys.notifStreakMinute, prefs.streakMinute);
    await box.put(StorageKeys.notifSessionHour, prefs.sessionHour);
    await box.put(StorageKeys.notifSessionMinute, prefs.sessionMinute);
    await box.put(StorageKeys.notifPermissionAsked, prefs.permissionAsked);
    if (prefs.fcmToken != null) {
      await box.put(StorageKeys.notifFcmToken, prefs.fcmToken);
    }
  }

  Future<void> saveFcmToken(String? token) async {
    if (token == null) {
      await HiveService.settingsBox.delete(StorageKeys.notifFcmToken);
    } else {
      await HiveService.settingsBox.put(StorageKeys.notifFcmToken, token);
    }
  }
}
