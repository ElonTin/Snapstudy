import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/home/domain/entities/upcoming_review.dart';
import 'package:snapstudy/features/home/presentation/utils/dashboard_formatters.dart';

class UpcomingReviewsSection extends StatelessWidget {
  const UpcomingReviewsSection({super.key, required this.reviews});

  final List<UpcomingReview> reviews;

  @override
  Widget build(BuildContext context) {
    final hasDue = reviews.any((r) => r.cardCount > 0 && r.sessionId.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Ôn tập sắp tới',
          trailing: hasDue
              ? AppButton(
                  label: 'Ôn tất cả',
                  variant: AppButtonVariant.text,
                  onPressed: () => context.push(RoutePaths.reviewQueue),
                )
              : null,
        ),
        const SizedBox(height: 4),
        ...reviews.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReviewTile(review: r),
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final UpcomingReview review;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Color(review.subjectColorValue);
    final isOverdue = review.isOverdue;
    final canStudy =
        review.cardCount > 0 && review.sessionId.isNotEmpty;

    return AppCard(
      onTap: canStudy
          ? () => context.push(
                RoutePaths.reviewQueuePath(sessionId: review.sessionId),
              )
          : () => context.showSnack(
                'Tạo flashcard từ buổi học để bắt đầu ôn tập',
              ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.replay_outlined, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.deckName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${review.subjectName} · ${review.cardCount} thẻ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOverdue
                  ? colors.errorContainer
                  : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DashboardFormatters.dueLabel(review.dueAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isOverdue ? colors.onErrorContainer : accent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
