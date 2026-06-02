import 'package:equatable/equatable.dart';

/// User preferences for local & push reminders.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.reviewRemindersEnabled = true,
    this.streakRemindersEnabled = true,
    this.sessionRemindersEnabled = true,
    this.reviewHour = 19,
    this.reviewMinute = 0,
    this.streakHour = 8,
    this.streakMinute = 30,
    this.sessionHour = 17,
    this.sessionMinute = 0,
    this.permissionAsked = false,
    this.fcmToken,
  });

  final bool reviewRemindersEnabled;
  final bool streakRemindersEnabled;
  final bool sessionRemindersEnabled;
  final int reviewHour;
  final int reviewMinute;
  final int streakHour;
  final int streakMinute;
  final int sessionHour;
  final int sessionMinute;
  final bool permissionAsked;
  final String? fcmToken;

  NotificationPreferences copyWith({
    bool? reviewRemindersEnabled,
    bool? streakRemindersEnabled,
    bool? sessionRemindersEnabled,
    int? reviewHour,
    int? reviewMinute,
    int? streakHour,
    int? streakMinute,
    int? sessionHour,
    int? sessionMinute,
    bool? permissionAsked,
    String? fcmToken,
    bool clearFcmToken = false,
  }) {
    return NotificationPreferences(
      reviewRemindersEnabled:
          reviewRemindersEnabled ?? this.reviewRemindersEnabled,
      streakRemindersEnabled:
          streakRemindersEnabled ?? this.streakRemindersEnabled,
      sessionRemindersEnabled:
          sessionRemindersEnabled ?? this.sessionRemindersEnabled,
      reviewHour: reviewHour ?? this.reviewHour,
      reviewMinute: reviewMinute ?? this.reviewMinute,
      streakHour: streakHour ?? this.streakHour,
      streakMinute: streakMinute ?? this.streakMinute,
      sessionHour: sessionHour ?? this.sessionHour,
      sessionMinute: sessionMinute ?? this.sessionMinute,
      permissionAsked: permissionAsked ?? this.permissionAsked,
      fcmToken: clearFcmToken ? null : (fcmToken ?? this.fcmToken),
    );
  }

  @override
  List<Object?> get props => [
        reviewRemindersEnabled,
        streakRemindersEnabled,
        sessionRemindersEnabled,
        reviewHour,
        reviewMinute,
        streakHour,
        streakMinute,
        sessionHour,
        sessionMinute,
        permissionAsked,
        fcmToken,
      ];
}
