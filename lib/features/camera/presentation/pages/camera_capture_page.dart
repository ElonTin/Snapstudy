import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/cached_file_image.dart';
import 'package:snapstudy/features/camera/presentation/providers/camera_providers.dart';
import 'package:snapstudy/features/camera/presentation/widgets/camera_controls_bar.dart';
import 'package:snapstudy/features/camera/presentation/widgets/capture_thumbnail_strip.dart';
import 'package:snapstudy/features/camera/presentation/widgets/document_crop_overlay.dart';
import 'package:snapstudy/features/camera/presentation/widgets/focusable_camera_preview.dart';

/// Full-screen camera — multi-shot, flash, crop overlay, gallery import.
class CameraCapturePage extends HookConsumerWidget {
  const CameraCapturePage({super.key, this.accentColor});

  final Color? accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useState<CameraController?>(null);
    final initError = useState<String?>(null);
    final isInitializing = useState(true);
    final flashEnabled = useState(false);
    final capturedPaths = useState<List<String>>([]);
    final selectedIndex = useState(0);
    final isCapturing = useState(false);

    final permissions = ref.read(cameraPermissionServiceProvider);
    final captureProcessing = ref.read(captureProcessingServiceProvider);
    final gallery = ref.read(galleryImportServiceProvider);

    Future<void> initCamera() async {
      isInitializing.value = true;
      initError.value = null;

      final granted = await permissions.ensureCameraGranted();
      if (!granted) {
        initError.value = 'Cần quyền camera để chụp ảnh bài giảng.';
        isInitializing.value = false;
        return;
      }

      try {
        final cameras = await availableCameras();
        if (cameras.isEmpty) {
          initError.value = 'Không tìm thấy camera trên thiết bị.';
          isInitializing.value = false;
          return;
        }

        final back = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        final cam = CameraController(
          back,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await cam.initialize();
        await configureCameraFocus(cam);
        await cam.setFlashMode(FlashMode.off);

        if (!context.mounted) {
          await cam.dispose();
          return;
        }

        controller.value = cam;
        isInitializing.value = false;
      } on CameraException catch (e) {
        initError.value = e.description ?? 'Không khởi tạo được camera.';
        isInitializing.value = false;
      } catch (e) {
        initError.value = e.toString();
        isInitializing.value = false;
      }
    }

    useEffect(() {
      initCamera();
      return () {
        controller.value?.dispose();
      };
    }, const []);

    Future<void> toggleFlash() async {
      final cam = controller.value;
      if (cam == null || !cam.value.isInitialized) return;

      final next = !flashEnabled.value;
      try {
        await cam.setFlashMode(next ? FlashMode.torch : FlashMode.off);
        flashEnabled.value = next;
      } catch (_) {
        if (context.mounted) {
          context.showSnack('Flash không khả dụng trên thiết bị này', isError: true);
        }
      }
    }

    Future<void> takePhoto() async {
      final cam = controller.value;
      if (cam == null || !cam.value.isInitialized || isCapturing.value) return;

      isCapturing.value = true;
      try {
        await HapticFeedback.mediumImpact();
        await stabilizeBeforeCapture(cam);
        final file = await cam.takePicture();
        if (!await File(file.path).exists()) {
          if (context.mounted) {
            context.showSnack('Không lưu được ảnh sau khi chụp', isError: true);
          }
          return;
        }
        final processed = await captureProcessing.processCapture(file.path);
        if (!await File(processed).exists()) {
          if (context.mounted) {
            context.showSnack('Xử lý ảnh thất bại', isError: true);
          }
          return;
        }
        capturedPaths.value = [...capturedPaths.value, processed];
        selectedIndex.value = capturedPaths.value.length - 1;
      } catch (e) {
        if (context.mounted) {
          context.showSnack('Chụp ảnh thất bại: $e', isError: true);
        }
      } finally {
        isCapturing.value = false;
      }
    }

    Future<void> importGallery() async {
      final granted = await permissions.ensureGalleryGranted();
      if (!granted) {
        if (context.mounted) {
          context.showSnack('Cần quyền truy cập ảnh', isError: true);
        }
        return;
      }

      try {
        final paths = await gallery.pickMultiple();
        if (paths.isEmpty) return;

        final processed = <String>[];
        for (final path in paths) {
          processed.add(await captureProcessing.processCapture(path));
        }
        capturedPaths.value = [...capturedPaths.value, ...processed];
        selectedIndex.value = capturedPaths.value.length - 1;
      } catch (_) {
        if (context.mounted) {
          context.showSnack('Không đọc được ảnh từ thư viện', isError: true);
        }
      }
    }

    void finish() {
      if (capturedPaths.value.isEmpty) {
        context.pop();
        return;
      }
      context.pop(capturedPaths.value);
    }

    void removeAt(int index) {
      final list = List<String>.from(capturedPaths.value);
      if (index < 0 || index >= list.length) return;
      list.removeAt(index);
      capturedPaths.value = list;
      if (selectedIndex.value >= list.length) {
        selectedIndex.value = list.isEmpty ? 0 : list.length - 1;
      }
    }

    final accent = accentColor ?? Theme.of(context).colorScheme.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPreview(
                isInitializing: isInitializing.value,
                initError: initError.value,
                controller: controller.value,
                capturedPaths: capturedPaths.value,
                selectedIndex: selectedIndex.value,
                onRetry: initCamera,
              ),
              const DocumentCropOverlay(),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    if (capturedPaths.value.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.95),
                              AppColors.secondary.withValues(alpha: 0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_camera,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${capturedPaths.value.length} ảnh',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CaptureThumbnailStrip(
                      paths: capturedPaths.value,
                      selectedIndex: selectedIndex.value,
                      onSelect: (i) => selectedIndex.value = i,
                      onRemove: removeAt,
                    ),
                    CameraControlsBar(
                      onGallery: importGallery,
                      onCapture: takePhoto,
                      onFlashToggle: toggleFlash,
                      onDone: finish,
                      flashEnabled: flashEnabled.value,
                      captureCount: capturedPaths.value.length,
                      isCapturing: isCapturing.value,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview({
    required bool isInitializing,
    required String? initError,
    required CameraController? controller,
    required List<String> capturedPaths,
    required int selectedIndex,
    required VoidCallback onRetry,
  }) {
    if (isInitializing) {
      return const AppLoading(
        fullScreen: true,
        message: 'Đang mở camera...',
      );
    }

    if (initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off_outlined,
                  color: Colors.white54,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                initError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Thử lại',
                icon: Icons.refresh,
                variant: AppButtonVariant.gold,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      );
    }

    if (controller != null && controller.value.isInitialized) {
      return FocusableCameraPreview(controller: controller);
    }

    if (capturedPaths.isNotEmpty) {
      final path =
          capturedPaths[selectedIndex.clamp(0, capturedPaths.length - 1)];
      return CachedFileImage(
        path: path,
        fit: BoxFit.cover,
        fullResolution: true,
      );
    }

    return const Center(
      child: Text(
        'Camera chưa sẵn sàng',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
