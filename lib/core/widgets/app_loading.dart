import 'package:flutter/material.dart';
import 'package:snapstudy/core/theme/app_colors.dart';

/// Full-screen or inline loading indicator with optional message.
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.message,
    this.fullScreen = false,
    this.size = 36,
  });

  final String? message;
  final bool fullScreen;
  final double size;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: Theme.of(context).colorScheme.primary,
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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

/// AI processing shimmer-style loader (used in later phases).
class AppAiLoading extends StatelessWidget {
  const AppAiLoading({super.key, this.label = 'Đang xử lý AI...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.aiGradientStart, AppColors.aiGradientEnd],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
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
