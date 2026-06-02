import 'package:equatable/equatable.dart';

/// Retention & review metrics for dashboard (Phase 11).
class SpacedRepetitionStats extends Equatable {
  const SpacedRepetitionStats({
    required this.dueNow,
    required this.dueToday,
    required this.overdue,
    required this.reviewedToday,
    required this.retentionPercent,
    required this.averageDifficulty,
    required this.nextReminderAt,
    required this.studyStreakDays,
  });

  final int dueNow;
  final int dueToday;
  final int overdue;
  final int reviewedToday;
  /// Estimated recall rate 0–100 from recent reviews.
  final int retentionPercent;
  final int averageDifficulty;
  final DateTime? nextReminderAt;
  final int studyStreakDays;

  bool get hasDue => dueNow > 0;

  @override
  List<Object?> get props => [
        dueNow,
        dueToday,
        overdue,
        reviewedToday,
        retentionPercent,
        averageDifficulty,
        nextReminderAt,
        studyStreakDays,
      ];
}
