import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/widgets/app_error_view.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';

/// Maps [AsyncValue] to loading / error / data UI consistently.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.loadingMessage,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final String? loadingMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => AppLoading(message: loadingMessage),
      error: (error, _) => AppErrorView(
        message: error.toString(),
        onRetry: onRetry,
      ),
      data: data,
    );
  }
}
