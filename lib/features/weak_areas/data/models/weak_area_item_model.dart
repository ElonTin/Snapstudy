import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_item.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_source.dart';

class WeakAreaItemModel {
  const WeakAreaItemModel({
    required this.label,
    required this.reason,
    required this.source,
    required this.priorityScore,
    this.referenceId,
    this.sessionId,
    this.sessionTitle,
  });

  factory WeakAreaItemModel.fromJson(Map<String, dynamic> json) {
    return WeakAreaItemModel(
      label: json['label'] as String,
      reason: json['reason'] as String,
      source: WeakAreaSource.values.byName(json['source'] as String),
      priorityScore: json['priorityScore'] as int,
      referenceId: json['referenceId'] as String?,
      sessionId: json['sessionId'] as String?,
      sessionTitle: json['sessionTitle'] as String?,
    );
  }

  final String label;
  final String reason;
  final WeakAreaSource source;
  final int priorityScore;
  final String? referenceId;
  final String? sessionId;
  final String? sessionTitle;

  Map<String, dynamic> toJson() => {
        'label': label,
        'reason': reason,
        'source': source.name,
        'priorityScore': priorityScore,
        if (referenceId != null) 'referenceId': referenceId,
        if (sessionId != null) 'sessionId': sessionId,
        if (sessionTitle != null) 'sessionTitle': sessionTitle,
      };

  WeakAreaItem toEntity() => WeakAreaItem(
        label: label,
        reason: reason,
        source: source,
        priorityScore: priorityScore,
        referenceId: referenceId,
        sessionId: sessionId,
        sessionTitle: sessionTitle,
      );

  static WeakAreaItemModel fromEntity(WeakAreaItem item) => WeakAreaItemModel(
        label: item.label,
        reason: item.reason,
        source: item.source,
        priorityScore: item.priorityScore,
        referenceId: item.referenceId,
        sessionId: item.sessionId,
        sessionTitle: item.sessionTitle,
      );
}
