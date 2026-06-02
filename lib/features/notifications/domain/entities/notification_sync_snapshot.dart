import 'package:equatable/equatable.dart';

/// Context used to build scheduled notification copy.
class NotificationSyncSnapshot extends Equatable {
  const NotificationSyncSnapshot({
    required this.dueCards,
    required this.overdueCards,
    required this.streakDays,
    required this.reviewedToday,
    required this.hasActiveSession,
    required this.pendingSessionCount,
  });

  final int dueCards;
  final int overdueCards;
  final int streakDays;
  final int reviewedToday;
  final bool hasActiveSession;
  final int pendingSessionCount;

  @override
  List<Object?> get props => [
        dueCards,
        overdueCards,
        streakDays,
        reviewedToday,
        hasActiveSession,
        pendingSessionCount,
      ];
}
