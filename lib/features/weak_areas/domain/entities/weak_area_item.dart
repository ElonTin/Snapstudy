import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_source.dart';

/// Một chủ đề / thẻ / câu hỏi người dùng còn yếu.
class WeakAreaItem extends Equatable {
  const WeakAreaItem({
    required this.label,
    required this.reason,
    required this.source,
    required this.priorityScore,
    this.referenceId,
    this.sessionId,
    this.sessionTitle,
  });

  final String label;
  final String reason;
  final WeakAreaSource source;
  final int priorityScore;
  final String? referenceId;
  final String? sessionId;
  final String? sessionTitle;

  @override
  List<Object?> get props => [
        label,
        reason,
        source,
        priorityScore,
        referenceId,
        sessionId,
        sessionTitle,
      ];
}
