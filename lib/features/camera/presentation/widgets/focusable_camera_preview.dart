import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Preview camera full màn hình + chạm để lấy nét.
class FocusableCameraPreview extends StatelessWidget {
  const FocusableCameraPreview({super.key, required this.controller});

  final CameraController controller;

  Future<void> _focusAt(Offset localPosition, Size size) async {
    if (!controller.value.isInitialized) return;

    final x = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final y = (localPosition.dy / size.height).clamp(0.0, 1.0);
    final point = Offset(x, y);

    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) => _focusAt(
            details.localPosition,
            Size(constraints.maxWidth, constraints.maxHeight),
          ),
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: previewSize.height,
                  height: previewSize.width,
                  child: CameraPreview(controller),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Cấu hình focus/exposure sau khi khởi tạo camera.
Future<void> configureCameraFocus(CameraController cam) async {
  try {
    await cam.setFocusMode(FocusMode.auto);
    await cam.setExposureMode(ExposureMode.auto);
  } catch (_) {}
}

/// Chờ lens ổn định trước khi chụp.
Future<void> stabilizeBeforeCapture(CameraController cam) async {
  try {
    await cam.setFocusMode(FocusMode.auto);
    await Future<void>.delayed(const Duration(milliseconds: 450));
  } catch (_) {}
}
