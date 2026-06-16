import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/utils/icon_helper.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/home/domain/entities/subject_summary.dart';
import 'package:snapstudy/features/home/presentation/widgets/dashboard_section_header.dart';

class SubjectCardsSection extends StatelessWidget {
  const SubjectCardsSection({super.key, required this.subjects});

  final List<SubjectSummary> subjects;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Môn học',
          actionLabel: 'Tất cả',
          onAction: () => context.push(RoutePaths.subjects),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: subjects.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return _SubjectCard(subject: subject);
            },
          ),
        ),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});

  final SubjectSummary subject;

  @override
  Widget build(BuildContext context) {
    final color = Color(subject.colorValue);
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140,
      child: AppCard(
        onTap: () => context.push(RoutePaths.subjectEditPath(subject.id)),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                iconFromCodePoint(subject.iconCodePoint),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    subject.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${subject.sessionCount} buổi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  if (subject.pendingReviews > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${subject.pendingReviews} ôn tập',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
