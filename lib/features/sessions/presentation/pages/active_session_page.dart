import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';

import 'package:snapstudy/features/sessions/presentation/providers/session_pipeline_provider.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/camera/presentation/providers/camera_providers.dart';
import 'package:snapstudy/features/camera/presentation/utils/camera_navigation.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/sessions/presentation/utils/session_formatters.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/capture_image_viewer.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/capture_queue_grid.dart';

/// Active session — timer, queue, native camera capture (Phase 6).
class ActiveSessionPage extends HookConsumerWidget {
  const ActiveSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(
        () => ref.read(activeSessionProvider.notifier).resumeTimer(),
      );
      return () {
        ref.read(activeSessionProvider.notifier).pauseTimer();
      };
    }, const []);

    final activeAsync = ref.watch(activeSessionProvider);
    final subjectColor = activeAsync.maybeWhen(
      data: (s) => s.session != null ? Color(s.session!.subjectColorValue) : null,
      orElse: () => null,
    );
    final isEnding = useState(false);

    Future<void> addFromGallery() async {
      final granted =
          await ref.read(cameraPermissionServiceProvider).ensureGalleryGranted();
      if (!granted) {
        if (context.mounted) {
          context.showSnack('Cần quyền truy cập ảnh', isError: true);
        }
        return;
      }

      final paths =
          await ref.read(galleryImportServiceProvider).pickMultiple();
      if (paths.isEmpty) return;

      final added = await ref
          .read(activeSessionProvider.notifier)
          .addCaptures(paths, processImages: true);
      if (context.mounted) {
        context.showSnack(
          added > 0
              ? 'Đã thêm $added ảnh vào hàng đợi'
              : 'Thêm ảnh thất bại — thử chọn ảnh khác',
          isError: added == 0,
        );
      }
    }

    Future<void> openCamera() async {
      final session = ref.read(activeSessionProvider).valueOrNull?.session;
      final paths = await openCameraCapture(
        context,
        accentColor: session != null
            ? Color(session.subjectColorValue)
            : subjectColor,
      );
      if (paths == null || paths.isEmpty || !context.mounted) return;

      final added =
          await ref.read(activeSessionProvider.notifier).addCaptures(paths);
      if (context.mounted) {
        context.showSnack(
          added > 0
              ? 'Đã thêm $added ảnh vào buổi học'
              : 'Không thêm được ảnh',
          isError: added == 0,
        );
      }
    }

    Future<void> endSession() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kết thúc buổi học?'),
          content: const Text(
            'Ảnh sẽ được OCR và tóm tắt AI tự động. '
            'Flashcard, quiz và mindmap tạo thủ công khi bạn cần.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tiếp tục'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kết thúc'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      isEnding.value = true;
      final session =
          await ref.read(activeSessionProvider.notifier).endSession();
      isEnding.value = false;

      if (session != null && context.mounted) {
        if (session.queue.isEmpty) {
          context.go(RoutePaths.home);
          context.showSnack('Buổi học đã kết thúc');
        } else {
          unawaited(
            ref.read(sessionPipelineProvider.notifier).runIfNeeded(session.id),
          );
          context.go(RoutePaths.sessionDetailPath(session.id));
          context.showSnack(
            'Đang xử lý OCR và AI — theo dõi tiến trình bên dưới',
          );
        }
      }
    }

    Future<void> cancelSession() async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Huỷ buổi học?'),
          content: const Text('Tất cả ảnh trong buổi này sẽ bị xoá.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Không'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('Huỷ buổi'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      final ok =
          await ref.read(activeSessionProvider.notifier).cancelSession();
      if (context.mounted) {
        if (ok) context.go(RoutePaths.home);
        context.showSnack(ok ? 'Đã huỷ buổi học' : 'Huỷ thất bại', isError: !ok);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buổi học đang diễn ra'),
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(RoutePaths.home),
        ),
        actions: [
          TextButton(
            onPressed: cancelSession,
            child: Text(
              'Huỷ',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
      body: activeAsync.when(
        loading: () => const AppLoading(fullScreen: true),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) {
          if (!state.hasActive || state.session == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(RoutePaths.sessionStart);
            });
            return const AppLoading(message: 'Đang chuyển hướng...');
          }

          final session = state.session!;

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(AppConstants.defaultPadding),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.aiGradientStart,
                      AppColors.aiGradientEnd,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(AppConstants.defaultRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            session.subjectName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: state.session!.isTimerRunning
                                ? Colors.redAccent
                                : Colors.amberAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.session!.isTimerRunning ? 'LIVE' : 'TẠM DỪNG',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      SessionFormatters.formatDuration(state.elapsed),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      session.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (session.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        alignment: WrapAlignment.center,
                        children: session.tags
                            .map(
                              (t) => Chip(
                                label: Text(t),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.15),
                                labelStyle: const TextStyle(color: Colors.white),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.defaultPadding,
                ),
                child: AppSectionHeader(
                  title: 'Hàng đợi chụp (${session.photoCount})',
                  trailing: AppButton(
                    label: 'Thư viện',
                    icon: Icons.photo_library_outlined,
                    variant: AppButtonVariant.text,
                    onPressed: addFromGallery,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  children: [
                    CaptureQueueGrid(
                      items: session.queue,
                      onAddTap: openCamera,
                      onImageTap: (item, index) => CaptureImageViewer.show(
                        context,
                        items: session.queue,
                        initialIndex: index,
                      ),
                      onRemove: (item) async {
                        final ok = await ref
                            .read(activeSessionProvider.notifier)
                            .removeCapture(item.id);
                        if (context.mounted && !ok) {
                          context.showSnack('Xoá ảnh thất bại', isError: true);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Ảnh được lưu gốc (nén nhẹ) → OCR sau khi kết thúc buổi.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    AppButton(
                      label: 'Mở camera',
                      icon: Icons.camera_alt_rounded,
                      expand: true,
                      onPressed: openCamera,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Kết thúc buổi học',
                      icon: Icons.check_circle_outline,
                      expand: true,
                      isLoading: isEnding.value,
                      onPressed: isEnding.value ? null : endSession,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: subjectColor != null
          ? FloatingActionButton.large(
              onPressed: openCamera,
              backgroundColor: subjectColor,
              child: const Icon(Icons.camera_alt_rounded, size: 32),
            )
          : null,
    );
  }
}

