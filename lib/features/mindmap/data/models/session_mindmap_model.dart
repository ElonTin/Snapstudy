import 'package:snapstudy/features/mindmap/data/models/mindmap_cluster_model.dart';
import 'package:snapstudy/features/mindmap/data/models/mindmap_node_model.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_status.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';

class SessionMindmapModel {
  const SessionMindmapModel({
    required this.sessionId,
    required this.title,
    required this.rootId,
    required this.nodes,
    required this.clusters,
    required this.status,
    required this.generatedAt,
    this.modelName,
    this.errorMessage,
  });

  factory SessionMindmapModel.fromJson(Map<String, dynamic> json) {
    final nodesRaw = json['nodes'] as List<dynamic>? ?? [];
    final clustersRaw = json['clusters'] as List<dynamic>? ?? [];
    return SessionMindmapModel(
      sessionId: json['sessionId'] as String,
      title: json['title'] as String,
      rootId: json['rootId'] as String,
      nodes: nodesRaw
          .map((e) => MindmapNodeModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      clusters: clustersRaw
          .map((e) => MindmapClusterModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      status: MindmapStatus.values.byName(json['status'] as String),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      modelName: json['modelName'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  final String sessionId;
  final String title;
  final String rootId;
  final List<MindmapNodeModel> nodes;
  final List<MindmapClusterModel> clusters;
  final MindmapStatus status;
  final DateTime generatedAt;
  final String? modelName;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'title': title,
        'rootId': rootId,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'clusters': clusters.map((c) => c.toJson()).toList(),
        'status': status.name,
        'generatedAt': generatedAt.toIso8601String(),
        if (modelName != null) 'modelName': modelName,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  SessionMindmap toEntity() => SessionMindmap(
        sessionId: sessionId,
        title: title,
        rootId: rootId,
        nodes: nodes.map((n) => n.toEntity()).toList(),
        clusters: clusters.map((c) => c.toEntity()).toList(),
        status: status,
        generatedAt: generatedAt,
        modelName: modelName,
        errorMessage: errorMessage,
      );

  static SessionMindmapModel fromEntity(SessionMindmap map) =>
      SessionMindmapModel(
        sessionId: map.sessionId,
        title: map.title,
        rootId: map.rootId,
        nodes: map.nodes.map(MindmapNodeModel.fromEntity).toList(),
        clusters: map.clusters.map(MindmapClusterModel.fromEntity).toList(),
        status: map.status,
        generatedAt: map.generatedAt,
        modelName: map.modelName,
        errorMessage: map.errorMessage,
      );
}
