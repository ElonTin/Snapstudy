import 'package:snapstudy/features/sessions/domain/entities/capture_queue_item.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';

class CaptureQueueItemModel {
  const CaptureQueueItemModel({
    required this.id,
    required this.localPath,
    required this.capturedAt,
    required this.status,
    this.thumbnailPath,
  });

  factory CaptureQueueItemModel.fromJson(Map<String, dynamic> json) {
    return CaptureQueueItemModel(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      status: CaptureItemStatus.values.byName(
        json['status'] as String? ?? 'pending',
      ),
    );
  }

  final String id;
  final String localPath;
  final String? thumbnailPath;
  final DateTime capturedAt;
  final CaptureItemStatus status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'localPath': localPath,
        'thumbnailPath': thumbnailPath,
        'capturedAt': capturedAt.toIso8601String(),
        'status': status.name,
      };

  CaptureQueueItem toEntity() => CaptureQueueItem(
        id: id,
        localPath: localPath,
        thumbnailPath: thumbnailPath,
        capturedAt: capturedAt,
        status: status,
      );

  static CaptureQueueItemModel fromEntity(CaptureQueueItem item) =>
      CaptureQueueItemModel(
        id: item.id,
        localPath: item.localPath,
        thumbnailPath: item.thumbnailPath,
        capturedAt: item.capturedAt,
        status: item.status,
      );
}
