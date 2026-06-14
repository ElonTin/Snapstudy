import 'package:flutter/material.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/home/domain/entities/ai_activity_item.dart';
import 'package:snapstudy/features/home/presentation/utils/dashboard_formatters.dart';

class AiActivitySection extends StatelessWidget {
  const AiActivitySection({super.key, required this.activities});

  final List<AiActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Hoạt động AI'),
        const SizedBox(height: 4),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < activities.length; i++) ...[
                _ActivityTile(activity: activities[i]),
                if (i < activities.length - 1)
                  Divider(
                    height: 1,
                    indent: 68,
                    endIndent: 16,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final AiActivityItem activity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = _iconForType(activity.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: activity.isCompleted
                  ? const LinearGradient(
                      colors: [
                        AppColors.aiGradientStart,
                        AppColors.aiGradientEnd,
                      ],
                    )
                  : null,
              color: activity.isCompleted
                  ? null
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: activity.isCompleted
                  ? Colors.white
                  : colors.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (!activity.isCompleted)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.secondary,
              ),
            )
          else
            Text(
              DashboardFormatters.relativeTime(activity.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }

  IconData _iconForType(AiActivityType type) => switch (type) {
        AiActivityType.summary => Icons.summarize_outlined,
        AiActivityType.flashcards => Icons.style_outlined,
        AiActivityType.quiz => Icons.quiz_outlined,
        AiActivityType.mindmap => Icons.account_tree_outlined,
        AiActivityType.ocr => Icons.document_scanner_outlined,
      };
}
