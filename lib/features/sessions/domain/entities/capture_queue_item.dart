import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';

/// Photo waiting in the active session capture queue.
class CaptureQueueItem extends Equatable {
  const CaptureQueueItem({
    required this.id,
    required this.localPath,
    required this.capturedAt,
    this.status = CaptureItemStatus.pending,
    this.thumbnailPath,
  });

  final String id;
  final String localPath;
  final String? thumbnailPath;
  final DateTime capturedAt;
  final CaptureItemStatus status;

  @override
  List<Object?> get props => [id, localPath, thumbnailPath, capturedAt, status];
}
