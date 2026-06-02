import 'package:flutter/material.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/mindmap/domain/services/mindmap_tree_layout.dart';
import 'package:snapstudy/features/mindmap/presentation/widgets/mindmap_edge_painter.dart';
import 'package:snapstudy/features/mindmap/presentation/widgets/mindmap_node_chip.dart';

/// Interactive mindmap with zoom/pan and expand/collapse.
class MindmapCanvas extends StatefulWidget {
  const MindmapCanvas({
    super.key,
    required this.mindmap,
    this.onNodeSelected,
  });

  final SessionMindmap mindmap;
  final ValueChanged<String>? onNodeSelected;

  @override
  State<MindmapCanvas> createState() => _MindmapCanvasState();
}

class _MindmapCanvasState extends State<MindmapCanvas> {
  final _collapsedIds = <String>{};

  void _toggleCollapse(String id) {
    setState(() {
      if (_collapsedIds.contains(id)) {
        _collapsedIds.remove(id);
      } else {
        _collapsedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = MindmapTreeLayout.compute(
      mindmap: widget.mindmap,
      collapsedIds: _collapsedIds,
    );
    final lineColor =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.45);

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(80),
      minScale: 0.25,
      maxScale: 2.5,
      clipBehavior: Clip.none,
      child: RepaintBoundary(
        child: SizedBox(
          width: layout.canvasSize.width,
          height: layout.canvasSize.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: layout.canvasSize,
                painter: MindmapEdgePainter(
                  edges: layout.edges,
                  lineColor: lineColor,
                ),
              ),
              ...layout.nodes.map((ln) {
                final cluster =
                    widget.mindmap.clusterFor(ln.node.clusterId);
                final isCollapsed = _collapsedIds.contains(ln.node.id);
                return Positioned(
                  left: ln.position.dx,
                  top: ln.position.dy,
                  child: MindmapNodeChip(
                    node: ln.node,
                    cluster: cluster,
                    isCollapsed: isCollapsed,
                    isRoot: ln.node.id == widget.mindmap.rootId,
                    onTap: () => widget.onNodeSelected?.call(ln.node.id),
                    onToggleCollapse: ln.node.hasChildren
                        ? () => _toggleCollapse(ln.node.id)
                        : null,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cluster legend for topic grouping.
class MindmapClusterLegend extends StatelessWidget {
  const MindmapClusterLegend({super.key, required this.mindmap});

  final SessionMindmap mindmap;

  @override
  Widget build(BuildContext context) {
    if (mindmap.clusters.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: mindmap.clusters.map((c) {
        final color = Color(c.colorValue);
        return Chip(
          avatar: CircleAvatar(backgroundColor: color, radius: 8),
          label: Text(c.label),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
