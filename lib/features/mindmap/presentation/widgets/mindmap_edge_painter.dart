import 'package:flutter/material.dart';
import 'package:snapstudy/features/mindmap/domain/services/mindmap_tree_layout.dart';

/// Draws Bézier edges between parent and child nodes.
class MindmapEdgePainter extends CustomPainter {
  MindmapEdgePainter({
    required this.edges,
    required this.lineColor,
  });

  final List<MindmapLayoutEdge> edges;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final edge in edges) {
      final path = Path()..moveTo(edge.from.dx, edge.from.dy);
      final midY = (edge.from.dy + edge.to.dy) / 2;
      path.cubicTo(
        edge.from.dx,
        midY,
        edge.to.dx,
        midY,
        edge.to.dx,
        edge.to.dy,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MindmapEdgePainter oldDelegate) =>
      oldDelegate.edges != edges || oldDelegate.lineColor != lineColor;
}
