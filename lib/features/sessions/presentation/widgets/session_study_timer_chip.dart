import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_study_timer_provider.dart';

/// Góc màn hình — hiển thị thời gian học buổi hiện tại.
class SessionStudyTimerChip extends ConsumerWidget {
  const SessionStudyTimerChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = ref.watch(sessionStudyTimerProvider);
    if (elapsed <= Duration.zero) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final label = ref.read(sessionStudyTimerProvider.notifier).formatted;

    return Material(
      elevation: 2,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
