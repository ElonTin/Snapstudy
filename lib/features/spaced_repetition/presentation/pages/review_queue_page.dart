import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
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
                child: Text(
                  'Nhớ ${stats.retentionPercent}%',
                  style: Theme.of(context).textTheme.labelMedium,
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
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${session.index + 1}/${session.queue.length}'),
                    const Spacer(),
                    _DifficultyChip(score: card.difficultyScore),
                    if (card.isOverdue)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.warning_amber, size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.subjectName} · ${item.deckTitle}',
                  style: Theme.of(context).textTheme.bodySmall,
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
                const SizedBox(height: 8),
                Text(
                  session.showBack
                      ? 'Chạm để xem câu hỏi'
                      : 'Chạm để lật thẻ',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 16),
                if (session.showBack) ...[
                  _RatingRow(
                    submitting: _submitting,
                    onRate: (r) => _onRate(r),
                  ),
                ] else
                  FilledButton(
                    onPressed: () =>
                        ref.read(reviewSessionControllerProvider.notifier).flip(),
                    child: const Text('Hiện đáp án'),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isBack
              ? [AppColors.aiGradientEnd, AppColors.aiGradientStart]
              : [AppColors.primary, AppColors.aiGradientStart],
        ),
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (hint != null && hint!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
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
              child: OutlinedButton(
                onPressed: submitting ? null : () => onRate(ReviewRating.again),
                child: const Text('Quên'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                onPressed: submitting ? null : () => onRate(ReviewRating.hard),
                child: const Text('Khó'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: submitting ? null : () => onRate(ReviewRating.good),
                child: const Text('Thuộc'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FilledButton.tonal(
                onPressed: submitting ? null : () => onRate(ReviewRating.easy),
                child: const Text('Dễ'),
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
    return Chip(
      label: Text('$label · $score'),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 72),
            const SizedBox(height: 16),
            Text(
              'Không có thẻ đến hạn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Hệ thống SM-2 sẽ nhắc khi đến lịch ôn.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onBack, child: const Text('Quay lại')),
          ],
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              'Hoàn tất $reviewed thẻ!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Ước tính ghi nhớ: $retention%'),
            const SizedBox(height: 24),
            FilledButton(onPressed: onFinish, child: const Text('Xong')),
          ],
        ),
      ),
    );
  }
}
