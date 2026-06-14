import 'package:equatable/equatable.dart';

enum SessionStatus { processing, ready, draft }

/// Recent study session summary for the dashboard list.
class RecentSession extends Equatable {
  const RecentSession({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.subtitle,
    required this.subjectColorValue,
    required this.photoCount,
    required this.startedAt,
    required this.status,
    this.aiSummaryReady = false,
  });

  final String id;
  final String title;
  final String subjectName;
  /// Chủ đề / dạng bài cụ thể (vd. Toán xác suất · biến cố).
  final String subtitle;
  final int subjectColorValue;
  final int photoCount;
  final DateTime startedAt;
  final SessionStatus status;
  final bool aiSummaryReady;

  @override
  List<Object?> get props => [
        id,
        title,
        subjectName,
        subtitle,
        subjectColorValue,
        photoCount,
        startedAt,
        status,
        aiSummaryReady,
      ];
}
