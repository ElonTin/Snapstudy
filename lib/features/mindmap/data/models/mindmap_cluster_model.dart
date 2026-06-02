import 'package:snapstudy/features/mindmap/domain/entities/mindmap_cluster.dart';

class MindmapClusterModel {
  const MindmapClusterModel({
    required this.id,
    required this.label,
    required this.colorValue,
  });

  factory MindmapClusterModel.fromJson(Map<String, dynamic> json) {
    return MindmapClusterModel(
      id: json['id'] as String,
      label: json['label'] as String,
      colorValue: json['colorValue'] as int,
    );
  }

  final String id;
  final String label;
  final int colorValue;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'colorValue': colorValue,
      };

  MindmapCluster toEntity() =>
      MindmapCluster(id: id, label: label, colorValue: colorValue);

  static MindmapClusterModel fromEntity(MindmapCluster c) => MindmapClusterModel(
        id: c.id,
        label: c.label,
        colorValue: c.colorValue,
      );
}
