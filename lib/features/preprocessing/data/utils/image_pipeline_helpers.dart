import 'package:image/image.dart' as img;
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
