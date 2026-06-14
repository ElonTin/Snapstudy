import 'package:flutter/material.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, text, gold }

/// Reusable button with consistent academic styling.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.size = AppButtonSize.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vPadding = size == AppButtonSize.large ? 16.0 : 14.0;
    final hPadding = size == AppButtonSize.large ? 28.0 : 24.0;
    final fontSize = size == AppButtonSize.large ? 16.0 : 14.0;

    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.outline ||
                      variant == AppButtonVariant.text
                  ? colors.primary
                  : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label, style: TextStyle(fontSize: fontSize)),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => _gradientButton(
          context,
          child,
          vPadding,
          hPadding,
          const [AppColors.aiGradientStart, AppColors.aiGradientEnd],
        ),
      AppButtonVariant.gold => _gradientButton(
          context,
          child,
          vPadding,
          hPadding,
          [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.85)],
          foreground: AppColors.primaryDark,
        ),
      AppButtonVariant.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
          ),
          child: child,
        ),
    };

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Widget _gradientButton(
    BuildContext context,
    Widget child,
    double vPadding,
    double hPadding,
    List<Color> gradientColors, {
    Color foreground = Colors.white,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(AppConstants.smallRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: foreground,
          padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        ),
        child: child,
      ),
    );
  }
}

enum AppButtonSize { medium, large }
