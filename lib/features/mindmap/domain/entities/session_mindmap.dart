import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_cluster.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_node.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_status.dart';

/// AI-generated knowledge map for a study session.
class SessionMindmap extends Equatable {
  const SessionMindmap({
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

  final String sessionId;
  final String title;
  final String rootId;
  final List<MindmapNode> nodes;
  final List<MindmapCluster> clusters;
  final MindmapStatus status;
  final DateTime generatedAt;
  final String? modelName;
  final String? errorMessage;

  bool get isReady => status == MindmapStatus.completed && nodes.isNotEmpty;

  Map<String, MindmapNode> get nodeById => {for (final n in nodes) n.id: n};

  MindmapNode? get root => nodeById[rootId];

  MindmapCluster? clusterFor(String? clusterId) {
    if (clusterId == null) return null;
    for (final c in clusters) {
      if (c.id == clusterId) return c;
    }
    return null;
  }

  Iterable<MindmapNode> childrenOf(String nodeId) sync* {
    final node = nodeById[nodeId];
    if (node == null) return;
    for (final id in node.childIds) {
      final child = nodeById[id];
      if (child != null) yield child;
    }
  }

  @override
  List<Object?> get props => [
        sessionId,
        title,
        rootId,
        nodes,
        clusters,
        status,
        generatedAt,
        modelName,
        errorMessage,
      ];
}
