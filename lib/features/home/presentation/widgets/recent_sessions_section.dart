import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/home/domain/entities/recent_session.dart';
import 'package:snapstudy/features/home/presentation/utils/dashboard_formatters.dart';
import 'package:snapstudy/features/home/presentation/widgets/dashboard_section_header.dart';

class RecentSessionsSection extends StatelessWidget {
  const RecentSessionsSection({super.key, required this.sessions});

  final List<RecentSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Buổi học gần đây',
          actionLabel: 'Xem tất cả',
          onAction: () => context.push(RoutePaths.sessionsHistory),
        ),
        ...sessions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SessionTile(session: s),
            )),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final RecentSession session;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Color(session.subjectColorValue);

    return AppCard(
      onTap: () => context.push(RoutePaths.sessionDetailPath(session.id)),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _statusIcon(session.status),
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(session: session),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  session.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.photoCount} ảnh · ${DashboardFormatters.relativeTime(session.startedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(SessionStatus status) => switch (status) {
        SessionStatus.ready => Icons.check_circle_outline,
        SessionStatus.processing => Icons.hourglass_top_outlined,
        SessionStatus.draft => Icons.edit_note_outlined,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.session});

  final RecentSession session;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (session.status) {
      SessionStatus.ready => (
          session.aiSummaryReady ? 'AI xong' : 'Sẵn sàng',
          Colors.green.shade700,
          Colors.green.withValues(alpha: 0.12),
        ),
      SessionStatus.processing => (
          'Đang xử lý',
          Colors.orange.shade800,
          Colors.orange.withValues(alpha: 0.12),
        ),
      SessionStatus.draft => (
          'Nháp',
          Colors.grey.shade700,
          Colors.grey.withValues(alpha: 0.12),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
