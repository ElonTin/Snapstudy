import 'dart:io';

import 'package:flutter/material.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';

/// Professional document scan animation overlay on image preview.
class DocumentScanOverlay extends StatefulWidget {
  const DocumentScanOverlay({
    super.key,
    required this.imagePath,
    this.label = 'Đang phân tích...',
    this.subLabel,
    this.progress,
    this.compact = false,
    this.height,
  });

  final String imagePath;
  final String label;
  final String? subLabel;
  final double? progress;
  final bool compact;
  final double? height;

  @override
  State<DocumentScanOverlay> createState() => _DocumentScanOverlayState();
}

class _DocumentScanOverlayState extends State<DocumentScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageHeight = widget.height ?? (widget.compact ? 160.0 : 280.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          child: SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.42),
                ),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _ScanLinePainter(progress: _controller.value),
                    size: Size.infinite,
                  ),
                ),
                _CornerBrackets(compact: widget.compact),
                if (!widget.compact)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: _ScanBadge(label: widget.label),
                  ),
              ],
            ),
          ),
        ),
        if (widget.compact) ...[
          const SizedBox(height: 10),
          _ScanBadge(label: widget.label, compact: true),
        ],
        if (widget.subLabel != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subLabel!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
        if (widget.progress != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: widget.progress,
              minHeight: 4,
              backgroundColor: colors.surfaceContainerHighest,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(widget.progress! * 100).round()}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.secondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}

class _ScanBadge extends StatelessWidget {
  const _ScanBadge({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: compact ? 12 : 14,
            height: compact ? 12 : 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.secondaryLight,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  const _CornerBrackets({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornerBracketPainter(
        color: AppColors.secondaryLight,
        strokeWidth: compact ? 2 : 2.5,
        inset: compact ? 10 : 16,
        armLength: compact ? 16 : 24,
      ),
      size: Size.infinite,
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  _ScanLinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    const lineHeight = 3.0;

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        AppColors.scanLineStart,
        AppColors.scanLineMid,
        AppColors.scanLineEnd,
      ],
    );

    final rect = Rect.fromLTWH(0, y - lineHeight / 2, size.width, lineHeight);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRect(rect, paint);

    final glowRect = Rect.fromLTWH(0, y - 20, size.width, 40);
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.secondary.withValues(alpha: 0.0),
          AppColors.secondary.withValues(alpha: 0.12),
          AppColors.secondary.withValues(alpha: 0.0),
        ],
      ).createShader(glowRect);
    canvas.drawRect(glowRect, glowPaint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.inset,
    required this.armLength,
  });

  final Color color;
  final double strokeWidth;
  final double inset;
  final double armLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final l = armLength;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(inset, inset + l)
        ..lineTo(inset, inset)
        ..lineTo(inset + l, inset),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - inset - l, inset)
        ..lineTo(w - inset, inset)
        ..lineTo(w - inset, inset + l),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(inset, h - inset - l)
        ..lineTo(inset, h - inset)
        ..lineTo(inset + l, h - inset),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - inset - l, h - inset)
        ..lineTo(w - inset, h - inset)
        ..lineTo(w - inset, h - inset - l),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) => false;
}

/// Multi-image scan carousel for ingest flow.
class DocumentScanCarousel extends StatelessWidget {
  const DocumentScanCarousel({
    super.key,
    required this.imagePaths,
    required this.label,
    this.subLabel,
    this.progress,
  });

  final List<String> imagePaths;
  final String label;
  final String? subLabel;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) {
      return AppAiLoading(label: label);
    }

    if (imagePaths.length == 1) {
      return DocumentScanOverlay(
        imagePath: imagePaths.first,
        label: label,
        subLabel: subLabel,
        progress: progress,
      );
    }

    return Column(
      children: [
        DocumentScanOverlay(
          imagePath: imagePaths.first,
          label: label,
          subLabel: subLabel,
          progress: progress,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            imagePaths.length.clamp(0, 5),
            (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == 0 ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == 0
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        if (imagePaths.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+ ${imagePaths.length - 1} ảnh khác',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}
