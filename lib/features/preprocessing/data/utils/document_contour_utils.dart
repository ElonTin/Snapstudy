import 'dart:math' as math;

import 'package:snapstudy/features/preprocessing/domain/entities/int_point.dart';

/// Orders 4 document corners: top-left, top-right, bottom-right, bottom-left.
List<IntPoint> orderDocumentQuad(List<IntPoint> points) {
  if (points.length != 4) return points;

  final sorted = List<IntPoint>.from(points);
  sorted.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
  final topLeft = sorted.first;
  final bottomRight = sorted.last;

  final remaining = points
      .where((p) => p.x != topLeft.x || p.y != topLeft.y)
      .where((p) => p.x != bottomRight.x || p.y != bottomRight.y)
      .toList();
  if (remaining.length != 2) return points;

  IntPoint topRight;
  IntPoint bottomLeft;
  if (remaining[0].x > remaining[1].x) {
    topRight = remaining[0];
    bottomLeft = remaining[1];
  } else {
    topRight = remaining[1];
    bottomLeft = remaining[0];
  }

  return [topLeft, topRight, bottomRight, bottomLeft];
}

/// Output size from ordered quad edge lengths.
(int width, int height) quadOutputSize(List<IntPoint> ordered) {
  final wTop = _distance(ordered[0], ordered[1]);
  final wBottom = _distance(ordered[3], ordered[2]);
  final hLeft = _distance(ordered[0], ordered[3]);
  final hRight = _distance(ordered[1], ordered[2]);
  final maxW = math.max(wTop, wBottom);
  final maxH = math.max(hLeft, hRight);
  return (maxW.round().clamp(1, 4096), maxH.round().clamp(1, 4096));
}

double _distance(IntPoint a, IntPoint b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}
