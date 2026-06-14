import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:snapstudy/features/preprocessing/data/utils/document_contour_utils.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/int_point.dart';

/// Grayscale + Sobel edge map (OpenCV Canny equivalent for Phase 7).
img.Image computeEdgeMap(img.Image source) {
  final gray = img.grayscale(source);
  final blurred = img.gaussianBlur(gray, radius: 2);
  return img.sobel(blurred);
}

/// Estimates a document quadrilateral from edge density (axis-aligned bounds).
List<IntPoint>? findDocumentQuadFromEdges(img.Image edgeMap) {
  final sampleW = edgeMap.width > 480 ? 480 : edgeMap.width;
  final sample = img.copyResize(edgeMap, width: sampleW);
  final scaleX = edgeMap.width / sample.width;
  final scaleY = edgeMap.height / sample.height;

  var minX = sample.width;
  var minY = sample.height;
  var maxX = 0;
  var maxY = 0;
  var hits = 0;
  const threshold = 72;

  for (var y = 0; y < sample.height; y++) {
    for (var x = 0; x < sample.width; x++) {
      if (sample.getPixel(x, y).luminance > threshold) {
        hits++;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  final area = (maxX - minX) * (maxY - minY);
  if (hits < 50 || area < sample.width * sample.height * 0.08) {
    return null;
  }

  final left = (minX * scaleX).round();
  final top = (minY * scaleY).round();
  final right = (maxX * scaleX).round().clamp(0, edgeMap.width - 1);
  final bottom = (maxY * scaleY).round().clamp(0, edgeMap.height - 1);

  return [
    IntPoint(left, top),
    IntPoint(right, top),
    IntPoint(right, bottom),
    IntPoint(left, bottom),
  ];
}

/// Crops non-empty content using luminance threshold.
img.Image? cropToContentBounds(img.Image source, {int padding = 8}) {
  var minX = source.width;
  var minY = source.height;
  var maxX = 0;
  var maxY = 0;
  var found = false;

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      if (source.getPixel(x, y).luminance < 245) {
        found = true;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (!found) return null;

  final x = (minX - padding).clamp(0, source.width - 1);
  final y = (minY - padding).clamp(0, source.height - 1);
  final w = (maxX - minX + 1 + padding * 2).clamp(1, source.width - x);
  final h = (maxY - minY + 1 + padding * 2).clamp(1, source.height - y);

  return img.copyCrop(source, x: x, y: y, width: w, height: h);
}

/// Bilinear perspective warp from ordered quad → rectangle output.
img.Image warpPerspective(img.Image source, List<IntPoint> orderedQuad) {
  if (orderedQuad.length != 4) return source;

  final ordered = orderDocumentQuad(orderedQuad);
  final (outW, outH) = quadOutputSize(ordered);
  if (outW < 8 || outH < 8) return source;

  final dst = img.Image(width: outW, height: outH);

  final srcPts = ordered
      .map((p) => math.Point<double>(p.x.toDouble(), p.y.toDouble()))
      .toList();
  final dstPts = [
    math.Point<double>(0, 0),
    math.Point<double>(outW.toDouble(), 0),
    math.Point<double>(outW.toDouble(), outH.toDouble()),
    math.Point<double>(0, outH.toDouble()),
  ];

  final matrix = _computeHomography(srcPts, dstPts);

  for (var y = 0; y < outH; y++) {
    for (var x = 0; x < outW; x++) {
      final src = _applyHomography(matrix, x.toDouble(), y.toDouble());
      final sx = src.x.round().clamp(0, source.width - 1);
      final sy = src.y.round().clamp(0, source.height - 1);
      dst.setPixel(x, y, source.getPixel(sx, sy));
    }
  }

  return dst;
}

List<double> _computeHomography(
  List<math.Point<double>> src,
  List<math.Point<double>> dst,
) {
  final a = List.generate(8, (_) => List<double>.filled(8, 0));
  final b = List<double>.filled(8, 0);

  for (var i = 0; i < 4; i++) {
    final sx = src[i].x;
    final sy = src[i].y;
    final dx = dst[i].x;
    final dy = dst[i].y;
    final row = i * 2;
    a[row][0] = sx;
    a[row][1] = sy;
    a[row][2] = 1;
    a[row][6] = -dx * sx;
    a[row][7] = -dx * sy;
    b[row] = dx;

    a[row + 1][3] = sx;
    a[row + 1][4] = sy;
    a[row + 1][5] = 1;
    a[row + 1][6] = -dy * sx;
    a[row + 1][7] = -dy * sy;
    b[row + 1] = dy;
  }

  final h = _solveLinear8(a, b);
  return [...h, 1.0];
}

List<double> _solveLinear8(List<List<double>> a, List<double> b) {
  final n = 8;
  final m = List.generate(n, (i) => [...a[i], b[i]]);

  for (var col = 0; col < n; col++) {
    var pivot = col;
    for (var row = col + 1; row < n; row++) {
      if (m[row][col].abs() > m[pivot][col].abs()) pivot = row;
    }
    final tmp = m[col];
    m[col] = m[pivot];
    m[pivot] = tmp;

    final div = m[col][col];
    if (div.abs() < 1e-12) continue;
    for (var j = col; j <= n; j++) {
      m[col][j] /= div;
    }

    for (var row = 0; row < n; row++) {
      if (row == col) continue;
      final factor = m[row][col];
      for (var j = col; j <= n; j++) {
        m[row][j] -= factor * m[col][j];
      }
    }
  }

  return List.generate(n, (i) => m[i][n]);
}

math.Point<double> _applyHomography(List<double> h, double x, double y) {
  final denom = h[6] * x + h[7] * y + h[8];
  if (denom.abs() < 1e-12) return math.Point<double>(x, y);
  final nx = (h[0] * x + h[1] * y + h[2]) / denom;
  final ny = (h[3] * x + h[4] * y + h[5]) / denom;
  return math.Point<double>(nx, ny);
}
