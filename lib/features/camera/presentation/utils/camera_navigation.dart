import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';

/// Opens the camera capture flow and returns local image paths.
Future<List<String>?> openCameraCapture(
  BuildContext context, {
  Color? accentColor,
}) {
  final query = accentColor != null
      ? '?color=${accentColor.toARGB32()}'
      : '';
  return context.push<List<String>>('${RoutePaths.cameraCapture}$query');
}
