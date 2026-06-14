import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/features/camera/presentation/providers/camera_providers.dart';
import 'package:snapstudy/features/camera/presentation/utils/camera_navigation.dart';
import 'package:snapstudy/features/home/presentation/providers/dashboard_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_pipeline_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';

Future<void> runAppendCamera(BuildContext context, String sessionId) async {
  final paths = await openCameraCapture(context);
  if (paths == null || paths.isEmpty || !context.mounted) return;
  await _append(context, sessionId, paths);
}

Future<void> runAppendGallery(BuildContext context, String sessionId) async {
  final container = ProviderScope.containerOf(context);
  final granted = await container
      .read(cameraPermissionServiceProvider)
      .ensureGalleryGranted();
  if (!granted) {
    if (context.mounted) {
      context.showSnack('Cần quyền truy cập ảnh', isError: true);
    }
    return;
  }

  final paths =
      await container.read(galleryImportServiceProvider).pickMultiple();
  if (paths.isEmpty || !context.mounted) return;
  await _append(context, sessionId, paths);
}

Future<void> _append(
  BuildContext context,
  String sessionId,
  List<String> paths,
) async {
  final ok = await context.push<bool>(
    RoutePaths.ingestProgressPath(sessionId: sessionId),
    extra: paths,
  );

  if (!context.mounted) return;

  if (ok == true) {
    context.showSnack('Đã thêm ảnh — AI đang cập nhật OCR');
    context.push(RoutePaths.sessionDetailPath(sessionId));
  }
}

Future<bool> appendImagesToSession(
  WidgetRef ref,
  String sessionId,
  List<String> imagePaths,
) async {
  final compress = ref.read(captureProcessingServiceProvider);
  final processed = <String>[];
  for (final path in imagePaths) {
    processed.add(await compress.prepareForStorage(path));
  }

  final result = await ref.read(sessionRepositoryProvider).appendCaptures(
        sessionId: sessionId,
        imagePaths: processed,
      );

  if (result.isFailure) return false;

  await ref.read(sessionPipelineProvider.notifier).run(sessionId);
  ref.invalidate(sessionDetailProvider(sessionId));
  ref.invalidate(dashboardProvider);
  return true;
}
