import 'package:snapstudy/features/mindmap/domain/entities/mindmap_node.dart';

class MindmapNodeModel {
  const MindmapNodeModel({
    required this.id,
    required this.label,
    this.parentId,
    this.clusterId,
    this.summary,
    this.childIds = const [],
  });

  factory MindmapNodeModel.fromJson(Map<String, dynamic> json) {
    return MindmapNodeModel(
      id: json['id'] as String,
      label: json['label'] as String,
      parentId: json['parentId'] as String?,
      clusterId: json['clusterId'] as String?,
      summary: json['summary'] as String?,
      childIds: (json['childIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  final String id;
  final String label;
  final String? parentId;
  final String? clusterId;
  final String? summary;
  final List<String> childIds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (parentId != null) 'parentId': parentId,
        if (clusterId != null) 'clusterId': clusterId,
        if (summary != null) 'summary': summary,
        'childIds': childIds,
      };

  MindmapNode toEntity() => MindmapNode(
        id: id,
        label: label,
        parentId: parentId,
        clusterId: clusterId,
        summary: summary,
        childIds: childIds,
      );

  static MindmapNodeModel fromEntity(MindmapNode n) => MindmapNodeModel(
        id: n.id,
        label: n.label,
        parentId: n.parentId,
        clusterId: n.clusterId,
        summary: n.summary,
        childIds: n.childIds,
      );
}
