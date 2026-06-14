import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/widgets/app_error_view.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_shimmer.dart';

/// Maps [AsyncValue] to loading / error / data UI consistently.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loadingMessage,
    this.onRetry,
    this.useSkeleton = true,
    this.fullScreenLoading = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String? loadingMessage;
  final VoidCallback? onRetry;
  final bool useSkeleton;
  final bool fullScreenLoading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => useSkeleton
          ? _AsyncValueSkeleton(
              message: loadingMessage,
              fullScreen: fullScreenLoading,
            )
          : AppLoading(
              message: loadingMessage,
              fullScreen: fullScreenLoading,
            ),
      error: (error, _) => AppErrorView(
        message: error.toString(),
        onRetry: onRetry,
      ),
      data: data,
    );
  }
}

class _AsyncValueSkeleton extends StatelessWidget {
  const _AsyncValueSkeleton({
    this.message,
    this.fullScreen = false,
  });

  final String? message;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final skeleton = Padding(
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ],
      ),
    );

    if (!fullScreen) return skeleton;
    return Scaffold(body: SafeArea(child: skeleton));
  }
}
