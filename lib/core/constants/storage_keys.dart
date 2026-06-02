/// Non-sensitive preference keys stored in Hive.
abstract final class StorageKeys {
  static const String onboardingCompleted = 'onboarding_completed';
  static const String subjectsSeeded = 'subjects_seeded';
  static const String subjectsList = 'subjects_list';
  static const String subjectFoldersList = 'subject_folders_list';

  /// Legacy — migrated to [sessionsIndex] + per-session keys.
  static const String sessionsList = 'sessions_list';

  /// Ordered session ids (newest first).
  static const String sessionsIndex = 'sessions_index';

  static const String activeSessionId = 'active_session_id';

  static String sessionKey(String id) => 'session_$id';

  /// Phase 11 — spaced repetition daily stats (Hive settings).
  static const String srReviewsTodayDate = 'sr_reviews_today_date';
  static const String srReviewsTodayCount = 'sr_reviews_today_count';
  static const String srRetentionEwma = 'sr_retention_ewma';
  static const String srStreakDays = 'sr_streak_days';
  static const String srLastStudyDate = 'sr_last_study_date';

  /// Phase 14 — notification preferences.
  static const String notifReviewEnabled = 'notif_review_enabled';
  static const String notifStreakEnabled = 'notif_streak_enabled';
  static const String notifSessionEnabled = 'notif_session_enabled';
  static const String notifReviewHour = 'notif_review_hour';
  static const String notifReviewMinute = 'notif_review_minute';
  static const String notifStreakHour = 'notif_streak_hour';
  static const String notifStreakMinute = 'notif_streak_minute';
  static const String notifSessionHour = 'notif_session_hour';
  static const String notifSessionMinute = 'notif_session_minute';
  static const String notifFcmToken = 'notif_fcm_token';
  static const String notifPermissionAsked = 'notif_permission_asked';
  static const String notificationHistory = 'notification_history';
  static const String notifLastPushRegisterAt = 'notif_last_push_register_at';
  static const String notifLastPushRegisterOk = 'notif_last_push_register_ok';
}
