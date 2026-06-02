import 'dart:ui';

import 'package:snapstudy/features/mindmap/domain/entities/mindmap_node.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';

class MindmapLayoutEdge {
  const MindmapLayoutEdge({
    required this.fromId,
    required this.toId,
    required this.from,
    required this.to,
  });

  final String fromId;
  final String toId;
  final Offset from;
  final Offset to;
}

class MindmapLayoutNode {
  const MindmapLayoutNode({
    required this.node,
    required this.position,
    required this.size,
    required this.depth,
  });

  final MindmapNode node;
  final Offset position;
  final Size size;
  final int depth;
}

class MindmapTreeLayout {
  MindmapTreeLayout({
    required this.nodes,
    required this.edges,
    required this.canvasSize,
  });

  final List<MindmapLayoutNode> nodes;
  final List<MindmapLayoutEdge> edges;
  final Size canvasSize;

  static const nodeWidth = 168.0;
  static const nodeHeight = 56.0;
  static const horizontalGap = 48.0;
  static const verticalGap = 28.0;
  static const padding = 40.0;

  static MindmapTreeLayout compute({
    required SessionMindmap mindmap,
    required Set<String> collapsedIds,
  }) {
    final root = mindmap.root;
    if (root == null) {
      return MindmapTreeLayout(
        nodes: [],
        edges: [],
        canvasSize: const Size(320, 240),
      );
    }

    final subtreeWidth = <String, double>{};

    double measure(String id) {
      if (collapsedIds.contains(id)) {
        subtreeWidth[id] = nodeWidth;
        return nodeWidth;
      }
      final node = mindmap.nodeById[id];
      if (node == null || node.childIds.isEmpty) {
        subtreeWidth[id] = nodeWidth;
        return nodeWidth;
      }
      var total = 0.0;
      for (var i = 0; i < node.childIds.length; i++) {
        total += measure(node.childIds[i]);
        if (i < node.childIds.length - 1) total += horizontalGap;
      }
      subtreeWidth[id] = total;
      return total;
    }

    measure(root.id);

    final layoutNodes = <MindmapLayoutNode>[];
    final edges = <MindmapLayoutEdge>[];
    var maxX = 0.0;
    var maxY = 0.0;

    void place(String id, double x, double y, int depth) {
      final node = mindmap.nodeById[id]!;
      final pos = Offset(x, y);
      layoutNodes.add(
        MindmapLayoutNode(
          node: node,
          position: pos,
          size: const Size(nodeWidth, nodeHeight),
          depth: depth,
        ),
      );
      maxX = (x + nodeWidth).clamp(maxX, double.infinity);
      maxY = (y + nodeHeight).clamp(maxY, double.infinity);

      if (collapsedIds.contains(id)) return;

      final children = node.childIds;
      if (children.isEmpty) return;

      var childX = x + (subtreeWidth[id]! - _childrenSpan(children, subtreeWidth)) / 2;
      final childY = y + nodeHeight + verticalGap;

      for (final childId in children) {
        final w = subtreeWidth[childId] ?? nodeWidth;
        final childCenterX = childX + w / 2;
        place(childId, childCenterX - nodeWidth / 2, childY, depth + 1);

        final parentCenter = Offset(
          x + nodeWidth / 2,
          y + nodeHeight,
        );
        final childCenter = Offset(
          childCenterX,
          childY,
        );
        edges.add(
          MindmapLayoutEdge(
            fromId: id,
            toId: childId,
            from: parentCenter,
            to: childCenter,
          ),
        );

        childX += w + horizontalGap;
      }
    }

    place(root.id, padding, padding, 0);

    return MindmapTreeLayout(
      nodes: layoutNodes,
      edges: edges,
      canvasSize: Size(
        maxX + padding,
        maxY + padding,
      ),
    );
  }

  static double _childrenSpan(
    List<String> children,
    Map<String, double> widths,
  ) {
    if (children.isEmpty) return 0;
    var total = 0.0;
    for (var i = 0; i < children.length; i++) {
      total += widths[children[i]] ?? nodeWidth;
      if (i < children.length - 1) total += horizontalGap;
    }
    return total;
  }
}
