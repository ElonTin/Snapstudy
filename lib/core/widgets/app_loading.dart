import 'package:flutter/material.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_shimmer.dart';

/// Full-screen or inline loading indicator with optional message.
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.message,
    this.fullScreen = false,
    this.size = 36,
    this.useSkeleton = false,
  });

  final String? message;
  final bool fullScreen;
  final double size;
  final bool useSkeleton;

  @override
  Widget build(BuildContext context) {
    if (useSkeleton && fullScreen) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeletonBox(width: 180, height: 28, radius: 8),
                const SizedBox(height: 12),
                const AppSkeletonBox(width: 240, height: 16, radius: 6),
                const SizedBox(height: 28),
                const AppSkeletonBox(height: 100, radius: AppConstants.defaultRadius),
                const SizedBox(height: 16),
                const AppSkeletonBox(height: 80, radius: AppConstants.defaultRadius),
                const SizedBox(height: 16),
                const AppSkeletonBox(height: 120, radius: AppConstants.defaultRadius),
                if (message != null) ...[
                  const Spacer(),
                  Center(
                    child: Text(
                      message!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: colors.secondary,
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (!fullScreen) return content;

    return Scaffold(
      body: Center(child: content),
    );
  }
}

/// AI processing loader with sparkle icon.
class AppAiLoading extends StatelessWidget {
  const AppAiLoading({super.key, this.label = 'Đang xử lý AI...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.aiGradientStart, AppColors.aiGradientEnd],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 20),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        const AppLoading(size: 28),
      ],
    );
  }
}
