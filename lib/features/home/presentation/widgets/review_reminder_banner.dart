import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/features/spaced_repetition/presentation/providers/spaced_repetition_providers.dart';

/// Smart SRS reminder on home when cards are due.
class ReviewReminderBanner extends ConsumerWidget {
  const ReviewReminderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(spacedRepetitionStatsProvider);

    return statsAsync.when(
      data: (stats) {
        if (!stats.hasDue) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(RoutePaths.reviewQueue),
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.aiGradientStart,
                      AppColors.aiGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active,
                          color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${stats.dueNow} thẻ cần ôn ngay',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              stats.overdue > 0
                                  ? '${stats.overdue} quá hạn · Ghi nhớ ~${stats.retentionPercent}%'
                                  : 'Ghi nhớ ~${stats.retentionPercent}% · Streak ${stats.studyStreakDays} ngày',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
