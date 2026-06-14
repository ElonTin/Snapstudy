import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/features/camera/presentation/providers/camera_providers.dart';
import 'package:snapstudy/features/camera/presentation/utils/camera_navigation.dart';

Future<void> runHomeCameraIngest(BuildContext context, WidgetRef ref) async {
  final paths = await openCameraCapture(context);
  if (paths == null || paths.isEmpty || !context.mounted) return;
  await _runIngest(context, paths);
}

Future<void> runHomeGalleryIngest(BuildContext context, WidgetRef ref) async {
  final granted =
      await ref.read(cameraPermissionServiceProvider).ensureGalleryGranted();
  if (!granted) {
    if (context.mounted) {
      context.showSnack('Cần quyền truy cập ảnh', isError: true);
    }
    return;
  }

  final paths = await ref.read(galleryImportServiceProvider).pickMultiple();
  if (paths.isEmpty || !context.mounted) return;
  await _runIngest(context, paths);
}

Future<void> _runIngest(BuildContext context, List<String> paths) async {
  final sessionId = await context.push<String?>(
    RoutePaths.ingestProgressPath(),
    extra: paths,
  );

  if (!context.mounted) return;

  if (sessionId != null && sessionId.isNotEmpty) {
    context.push(RoutePaths.sessionDetailPath(sessionId));
    context.showSnack('Đã lưu bài học — OCR và tóm tắt đang chạy nền');
  }
}
