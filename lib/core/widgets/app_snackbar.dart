import 'package:flutter/material.dart';
import 'package:snapstudy/core/constants/app_constants.dart';

enum AppSnackType { info, success, error }

/// Styled floating snackbar helper.
abstract final class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackType type = AppSnackType.info,
    Duration duration = AppConstants.snackBarDuration,
  }) {
    final colors = Theme.of(context).colorScheme;
    final (icon, bg, fg) = switch (type) {
      AppSnackType.success => (
          Icons.check_circle_rounded,
          colors.tertiaryContainer,
          colors.onTertiaryContainer,
        ),
      AppSnackType.error => (
          Icons.error_outline_rounded,
          colors.errorContainer,
          colors.onErrorContainer,
        ),
      AppSnackType.info => (
          Icons.info_outline_rounded,
          colors.surfaceContainerHigh,
          colors.onSurface,
        ),
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: fg, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.smallRadius),
        ),
        elevation: 4,
      ),
    );
  }
}
