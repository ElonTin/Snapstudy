import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Phép biến đổi zoom/pan cho mindmap — zoom quanh điểm chạm (ngón tay / chuột).
abstract final class MindmapViewportTransform {
  MindmapViewportTransform._();

  static const minScale = 0.12;
  static const maxScale = 3.0;

  static double readScale(Matrix4 matrix) => matrix.getMaxScaleOnAxis();

  static Matrix4 fit({
    required Size viewport,
    required Size canvas,
    double paddingFactor = 0.9,
  }) {
    if (viewport.width <= 0 ||
        viewport.height <= 0 ||
        canvas.width <= 0 ||
        canvas.height <= 0) {
      return Matrix4.identity();
    }

    final scale =
        math
            .min(viewport.width / canvas.width, viewport.height / canvas.height)
            .clamp(minScale, 1.2) *
        paddingFactor;
    final dx = (viewport.width - canvas.width * scale) / 2;
    final dy = (viewport.height - canvas.height * scale) / 2;

    final matrix = Matrix4.identity()..scaleByDouble(scale, scale, scale, 1);
    matrix.setTranslationRaw(dx, dy, 0);
    return matrix;
  }

  /// Zoom nhân [factor] quanh [focal] (tọa độ trong khung viewport).
  static Matrix4 zoomAt({
    required Matrix4 current,
    required Offset focal,
    required double factor,
  }) {
    final currentScale = readScale(current);
    final newScale = (currentScale * factor).clamp(minScale, maxScale);
    if ((newScale - currentScale).abs() < 0.001) return current;

    final translation = current.getTranslation();
    final sceneX = (focal.dx - translation.x) / currentScale;
    final sceneY = (focal.dy - translation.y) / currentScale;

    final tx = focal.dx - sceneX * newScale;
    final ty = focal.dy - sceneY * newScale;
    final matrix = Matrix4.identity()
      ..scaleByDouble(newScale, newScale, newScale, 1);
    matrix.setTranslationRaw(tx, ty, 0);
    return matrix;
  }

  static int zoomPercent(Matrix4 matrix) =>
      (readScale(matrix) * 100).round().clamp(12, 300);
}
