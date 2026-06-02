import 'package:equatable/equatable.dart';

/// Topic cluster grouping nodes on the mindmap.
class MindmapCluster extends Equatable {
  const MindmapCluster({
    required this.id,
    required this.label,
    required this.colorValue,
  });

  final String id;
  final String label;
  final int colorValue;

  @override
  List<Object?> get props => [id, label, colorValue];
}
