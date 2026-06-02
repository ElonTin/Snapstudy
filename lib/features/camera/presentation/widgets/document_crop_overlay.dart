import 'package:flutter/material.dart';
import 'package:snapstudy/features/camera/domain/constants/camera_constants.dart';

/// Semi-transparent mask with a document-style crop guide.
class DocumentCropOverlay extends StatelessWidget {
  const DocumentCropOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _DocumentCropPainter(
              widthFraction: CameraConstants.cropGuideWidthFraction,
              heightFraction: CameraConstants.cropGuideHeightFraction,
              cornerRadius: CameraConstants.cropGuideCornerRadius,
              strokeWidth: CameraConstants.cropGuideStrokeWidth,
            ),
          );
        },
      ),
    );
  }
}

class _DocumentCropPainter extends CustomPainter {
  _DocumentCropPainter({
    required this.widthFraction,
    required this.heightFraction,
    required this.cornerRadius,
    required this.strokeWidth,
  });

  final double widthFraction;
  final double heightFraction;
  final double cornerRadius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final guideWidth = size.width * widthFraction;
    final guideHeight = size.height * heightFraction;
    final left = (size.width - guideWidth) / 2;
    final top = (size.height - guideHeight) / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, guideWidth, guideHeight),
      Radius.circular(cornerRadius),
    );

    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()..addRRect(rect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      dimPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rect, borderPaint);

    const cornerLen = 22.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLen, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLen),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + guideWidth, top),
      Offset(left + guideWidth - cornerLen, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + guideWidth, top),
      Offset(left + guideWidth, top + cornerLen),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + guideHeight),
      Offset(left + cornerLen, top + guideHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + guideHeight),
      Offset(left, top + guideHeight - cornerLen),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + guideWidth, top + guideHeight),
      Offset(left + guideWidth - cornerLen, top + guideHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + guideWidth, top + guideHeight),
      Offset(left + guideWidth, top + guideHeight - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DocumentCropPainter oldDelegate) => false;
}
