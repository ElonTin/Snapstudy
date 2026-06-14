/// Stable IDs for scheduled local notifications.
abstract final class NotificationIds {
  static const int reviewDaily = 1001;
  static const int streakDaily = 1002;
  static const int sessionDaily = 1003;

  /// Per-card SRS reminders use [cardReminderBase, cardReminderMax).
  static const int cardReminderBase = 3000;
  static const int cardReminderMax = 13000;

  static int cardReminderId(String cardId) =>
      cardReminderBase + (cardId.hashCode.abs() % (cardReminderMax - cardReminderBase));
}
