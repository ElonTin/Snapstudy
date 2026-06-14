import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_empty_state.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/spaced_repetition/presentation/providers/spaced_repetition_providers.dart';

/// Optimized spaced-repetition review session (Phase 11).
class ReviewQueuePage extends ConsumerStatefulWidget {
  const ReviewQueuePage({super.key, this.sessionId});

  final String? sessionId;

  @override
  ConsumerState<ReviewQueuePage> createState() => _ReviewQueuePageState();
}

class _ReviewQueuePageState extends ConsumerState<ReviewQueuePage> {
  var _submitting = false;

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(reviewQueueProvider(widget.sessionId));
    final session = ref.watch(reviewSessionControllerProvider);
    final statsAsync = ref.watch(spacedRepetitionStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sessionId == null ? 'Ôn tập SRS' : 'Ôn bộ thẻ',
        ),
        actions: [
          statsAsync.when(
            data: (stats) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Nhớ ${stats.retentionPercent}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: queueAsync.when(
        loading: () => const AppLoading(
          fullScreen: true,
          useSkeleton: true,
          message: 'Đang tải hàng đợi ôn tập...',
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (queue) {
          if (queue.isEmpty) {
            return _EmptyState(onBack: () => context.pop());
          }

          if (session.queue.isEmpty && !session.completed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(reviewSessionControllerProvider.notifier).loadQueue(queue);
            });
          }

          if (session.completed) {
            return _DoneState(
              reviewed: queue.length,
              retention: statsAsync.valueOrNull?.retentionPercent ?? 0,
              onFinish: () => context.pop(),
            );
          }

          final item = session.current;
          if (item == null) {
            return const AppLoading(message: 'Đang chuẩn bị...');
          }

          final card = item.card;
          final progress = (session.index + 1) / session.queue.length;

          return Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${session.index + 1}/${session.queue.length}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                          _DifficultyChip(score: card.difficultyScore),
                          if (card.isOverdue)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 20,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.subjectName} · ${item.deckTitle}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(reviewSessionControllerProvider.notifier).flip(),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: _ReviewCardFace(
                        key: ValueKey('${card.id}_${session.showBack}'),
                        text: session.showBack ? card.back : card.front,
                        isBack: session.showBack,
                        hint: !session.showBack ? card.hint : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  session.showBack
                      ? 'Chạm để xem câu hỏi'
                      : 'Chạm để lật thẻ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                if (session.showBack) ...[
                  _RatingRow(
                    submitting: _submitting,
                    onRate: (r) => _onRate(r),
                  ),
                ] else
                  AppButton(
                    label: 'Hiện đáp án',
                    variant: AppButtonVariant.primary,
                    expand: true,
                    onPressed: () =>
                        ref.read(reviewSessionControllerProvider.notifier).flip(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onRate(ReviewRating rating) async {
    setState(() => _submitting = true);
    final ok =
        await ref.read(reviewSessionControllerProvider.notifier).rate(rating);
    setState(() => _submitting = false);
    if (mounted && ok) {
      final label = switch (rating) {
        ReviewRating.again => 'Sẽ ôn lại sớm',
        ReviewRating.hard => 'Lịch ôn đã cập nhật (khó)',
        ReviewRating.good => 'Đã ghi nhận',
        ReviewRating.easy => 'Lịch ôn đã kéo dài',
      };
      context.showSnack(label);
    }
  }
}

class _ReviewCardFace extends StatelessWidget {
  const _ReviewCardFace({
    super.key,
    required this.text,
    required this.isBack,
    this.hint,
  });

  final String text;
  final bool isBack;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBack
              ? [AppColors.aiGradientEnd, AppColors.aiGradientStart]
              : [AppColors.primary, AppColors.aiGradientStart],
        ),
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isBack ? 'MẶT SAU' : 'MẶT TRƯỚC',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
            if (hint != null && hint!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.submitting, required this.onRate});

  final bool submitting;
  final ValueChanged<ReviewRating> onRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Quên',
                variant: AppButtonVariant.outline,
                expand: true,
                isLoading: submitting,
                onPressed: submitting ? null : () => onRate(ReviewRating.again),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: 'Khó',
                variant: AppButtonVariant.outline,
                expand: true,
                isLoading: submitting,
                onPressed: submitting ? null : () => onRate(ReviewRating.hard),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Thuộc',
                variant: AppButtonVariant.primary,
                expand: true,
                isLoading: submitting,
                onPressed: submitting ? null : () => onRate(ReviewRating.good),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: 'Dễ',
                variant: AppButtonVariant.secondary,
                expand: true,
                isLoading: submitting,
                onPressed: submitting ? null : () => onRate(ReviewRating.easy),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final label = score >= 70 ? 'Dễ' : score >= 40 ? 'TB' : 'Khó';
    final colors = Theme.of(context).colorScheme;
    final chipColor = score >= 70
        ? colors.tertiaryContainer
        : score >= 40
            ? colors.secondaryContainer
            : colors.errorContainer;
    final textColor = score >= 70
        ? colors.onTertiaryContainer
        : score >= 40
            ? colors.onSecondaryContainer
            : colors.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label · $score',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.check_circle_outline,
      title: 'Không có thẻ đến hạn',
      subtitle: 'Hệ thống SM-2 sẽ nhắc khi đến lịch ôn.',
      action: AppButton(
        label: 'Quay lại',
        variant: AppButtonVariant.primary,
        onPressed: onBack,
      ),
    );
  }
}

class _DoneState extends StatelessWidget {
  const _DoneState({
    required this.reviewed,
    required this.retention,
    required this.onFinish,
  });

  final int reviewed;
  final int retention;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'Hoàn tất $reviewed thẻ!',
      subtitle: 'Ước tính ghi nhớ: $retention%',
      action: AppButton(
        label: 'Xong',
        variant: AppButtonVariant.gold,
        onPressed: onFinish,
      ),
    );
  }
}
