import 'package:equatable/equatable.dart';

/// One node in the knowledge graph.
class MindmapNode extends Equatable {
  const MindmapNode({
    required this.id,
    required this.label,
    this.parentId,
    this.clusterId,
    this.summary,
    this.childIds = const [],
  });

  final String id;
  final String label;
  final String? parentId;
  final String? clusterId;
  final String? summary;
  final List<String> childIds;

  bool get hasChildren => childIds.isNotEmpty;

  @override
  List<Object?> get props => [id, label, parentId, clusterId, summary, childIds];
}
