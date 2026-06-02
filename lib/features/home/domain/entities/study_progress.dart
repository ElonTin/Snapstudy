import 'package:equatable/equatable.dart';

/// Aggregated study statistics shown on the dashboard.
class StudyProgress extends Equatable {
  const StudyProgress({
    required this.sessionsThisWeek,
    required this.cardsReviewed,
    required this.studyMinutesToday,
    required this.streakDays,
    required this.weeklyGoalPercent,
  });

  final int sessionsThisWeek;
  final int cardsReviewed;
  final int studyMinutesToday;
  final int streakDays;
  final double weeklyGoalPercent;

  @override
  List<Object?> get props => [
        sessionsThisWeek,
        cardsReviewed,
        studyMinutesToday,
        streakDays,
        weeklyGoalPercent,
      ];
}
