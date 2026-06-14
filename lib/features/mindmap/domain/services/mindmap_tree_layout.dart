import 'dart:math' as math;
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

class MindmapLayoutMetrics {
  const MindmapLayoutMetrics({
    this.nodeWidth = 152,
    this.nodeHeight = 52,
    this.horizontalGap = 36,
    this.verticalGap = 32,
    this.padding = 32,
  });

  final double nodeWidth;
  final double nodeHeight;
  final double horizontalGap;
  final double verticalGap;
  final double padding;
}

class MindmapTreeLayout {
  MindmapTreeLayout({
    required this.nodes,
    required this.edges,
    required this.canvasSize,
    required this.metrics,
  });

  final List<MindmapLayoutNode> nodes;
  final List<MindmapLayoutEdge> edges;
  final Size canvasSize;
  final MindmapLayoutMetrics metrics;

  /// Kích thước mặc định — đồng bộ với [MindmapNodeChip].
  static const nodeWidth = 152.0;
  static const nodeHeight = 52.0;

  static MindmapTreeLayout compute({
    required SessionMindmap mindmap,
    required Set<String> collapsedIds,
    MindmapLayoutMetrics? metrics,
  }) {
    final m = metrics ?? const MindmapLayoutMetrics();
    final root = mindmap.root;
    if (root == null) {
      return MindmapTreeLayout(
        nodes: [],
        edges: [],
        canvasSize: const Size(320, 240),
        metrics: m,
      );
    }

    final subtreeWidth = <String, double>{};

    double measure(String id) {
      if (collapsedIds.contains(id)) {
        subtreeWidth[id] = m.nodeWidth;
        return m.nodeWidth;
      }
      final node = mindmap.nodeById[id];
      if (node == null || node.childIds.isEmpty) {
        subtreeWidth[id] = m.nodeWidth;
        return m.nodeWidth;
      }
      var total = 0.0;
      for (var i = 0; i < node.childIds.length; i++) {
        total += measure(node.childIds[i]);
        if (i < node.childIds.length - 1) total += m.horizontalGap;
      }
      subtreeWidth[id] = total;
      return total;
    }

    measure(root.id);

    final layoutNodes = <MindmapLayoutNode>[];
    final edges = <MindmapLayoutEdge>[];

    void place(String id, double x, double y, int depth) {
      final node = mindmap.nodeById[id]!;
      layoutNodes.add(
        MindmapLayoutNode(
          node: node,
          position: Offset(x, y),
          size: Size(m.nodeWidth, m.nodeHeight),
          depth: depth,
        ),
      );

      if (collapsedIds.contains(id)) return;

      final children = node.childIds;
      if (children.isEmpty) return;

      var childX =
          x + (subtreeWidth[id]! - _childrenSpan(children, subtreeWidth, m)) / 2;
      final childY = y + m.nodeHeight + m.verticalGap;

      for (final childId in children) {
        final w = subtreeWidth[childId] ?? m.nodeWidth;
        final childCenterX = childX + w / 2;
        place(childId, childCenterX - m.nodeWidth / 2, childY, depth + 1);

        edges.add(
          MindmapLayoutEdge(
            fromId: id,
            toId: childId,
            from: Offset(x + m.nodeWidth / 2, y + m.nodeHeight),
            to: Offset(childCenterX, childY),
          ),
        );

        childX += w + m.horizontalGap;
      }
    }

    // Đặt gốc giữa theo chiều ngang của toàn cây.
    final treeWidth = subtreeWidth[root.id] ?? m.nodeWidth;
    final rootX = m.padding + math.max(0, (treeWidth - m.nodeWidth) / 2);
    place(root.id, rootX, m.padding, 0);

    return _normalize(layoutNodes, edges, m);
  }

  static MindmapTreeLayout _normalize(
    List<MindmapLayoutNode> nodes,
    List<MindmapLayoutEdge> edges,
    MindmapLayoutMetrics m,
  ) {
    if (nodes.isEmpty) {
      return MindmapTreeLayout(
        nodes: nodes,
        edges: edges,
        canvasSize: const Size(320, 240),
        metrics: m,
      );
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = 0.0;
    var maxY = 0.0;

    for (final ln in nodes) {
      minX = math.min(minX, ln.position.dx);
      minY = math.min(minY, ln.position.dy);
      maxX = math.max(maxX, ln.position.dx + ln.size.width);
      maxY = math.max(maxY, ln.position.dy + ln.size.height);
    }

    final shift = Offset(m.padding - minX, m.padding - minY);
    final normalizedNodes = nodes
        .map(
          (ln) => MindmapLayoutNode(
            node: ln.node,
            position: ln.position + shift,
            size: ln.size,
            depth: ln.depth,
          ),
        )
        .toList();
    final normalizedEdges = edges
        .map(
          (e) => MindmapLayoutEdge(
            fromId: e.fromId,
            toId: e.toId,
            from: e.from + shift,
            to: e.to + shift,
          ),
        )
        .toList();

    return MindmapTreeLayout(
      nodes: normalizedNodes,
      edges: normalizedEdges,
      canvasSize: Size(
        maxX - minX + m.padding * 2,
        maxY - minY + m.padding * 2,
      ),
      metrics: m,
    );
  }

  static double _childrenSpan(
    List<String> children,
    Map<String, double> widths,
    MindmapLayoutMetrics m,
  ) {
    if (children.isEmpty) return 0;
    var total = 0.0;
    for (var i = 0; i < children.length; i++) {
      total += widths[children[i]] ?? m.nodeWidth;
      if (i < children.length - 1) total += m.horizontalGap;
    }
    return total;
  }
}
