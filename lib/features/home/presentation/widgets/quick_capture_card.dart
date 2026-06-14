import 'package:flutter/material.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';

/// Hai nút chính: chụp bài và import thư viện — AI tự phân môn + OCR + tóm tắt.
class QuickCaptureCard extends StatelessWidget {
  const QuickCaptureCard({
    super.key,
    required this.onCapture,
    required this.onGalleryImport,
  });

  final VoidCallback onCapture;
  final VoidCallback onGalleryImport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(
          title: 'Thêm bài học',
          subtitle: 'Chụp hoặc import ảnh — AI tự nhận môn, OCR và tóm tắt',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                onTap: onCapture,
                icon: Icons.camera_alt_rounded,
                label: 'Chụp bài',
                gradient: const [
                  AppColors.aiGradientStart,
                  AppColors.aiGradientEnd,
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                onTap: onGalleryImport,
                icon: Icons.photo_library_rounded,
                label: 'Import ảnh',
                gradient: const [
                  AppColors.secondary,
                  AppColors.secondaryLight,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.gradient,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
