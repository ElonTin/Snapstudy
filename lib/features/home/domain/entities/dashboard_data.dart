import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/home/domain/entities/ai_activity_item.dart';
import 'package:snapstudy/features/home/domain/entities/recent_session.dart';
import 'package:snapstudy/features/home/domain/entities/study_progress.dart';
import 'package:snapstudy/features/home/domain/entities/subject_summary.dart';
import 'package:snapstudy/features/home/domain/entities/upcoming_review.dart';

/// Full dashboard payload for the home screen.
class DashboardData extends Equatable {
  const DashboardData({
    required this.progress,
    required this.subjects,
    required this.recentSessions,
    required this.aiActivities,
    required this.upcomingReviews,
  });

  final StudyProgress progress;
  final List<SubjectSummary> subjects;
  final List<RecentSession> recentSessions;
  final List<AiActivityItem> aiActivities;
  final List<UpcomingReview> upcomingReviews;

  @override
  List<Object?> get props =>
      [progress, subjects, recentSessions, aiActivities, upcomingReviews];
}
