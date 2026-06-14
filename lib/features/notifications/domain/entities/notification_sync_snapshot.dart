import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/notifications/domain/entities/card_review_reminder.dart';

/// Context used to build scheduled notification copy.
class NotificationSyncSnapshot extends Equatable {
  const NotificationSyncSnapshot({
    required this.dueCards,
    required this.overdueCards,
    required this.streakDays,
    required this.reviewedToday,
    required this.hasActiveSession,
    required this.pendingSessionCount,
    this.upcomingCardReminders = const [],
  });

  final int dueCards;
  final int overdueCards;
  final int streakDays;
  final int reviewedToday;
  final bool hasActiveSession;
  final int pendingSessionCount;
  final List<CardReviewReminder> upcomingCardReminders;

  @override
  List<Object?> get props => [
        dueCards,
        overdueCards,
        streakDays,
        reviewedToday,
        hasActiveSession,
        pendingSessionCount,
        upcomingCardReminders,
      ];
}
