import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/notifications/notification_payload.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/features/home/presentation/utils/dashboard_formatters.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_record.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_source.dart';
import 'package:snapstudy/features/notifications/presentation/providers/notification_providers.dart';

class NotificationHistoryPage extends ConsumerWidget {
  const NotificationHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(notificationHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hộp thông báo'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref
                  .read(notificationRepositoryProvider)
                  .markAllHistoryRead();
              ref.invalidate(notificationHistoryProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: const Text('Đọc hết'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xóa lịch sử?'),
                  content: const Text(
                    'Toàn bộ thông báo đã lưu sẽ bị xóa.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref
                    .read(notificationRepositoryProvider)
                    .clearHistory();
                ref.invalidate(notificationHistoryProvider);
                ref.invalidate(unreadNotificationCountProvider);
              }
            },
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const AppLoading(fullScreen: true),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Chưa có thông báo nào được lưu.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return _HistoryTile(
                record: item,
                onTap: () => _openItem(context, ref, item),
                onDismiss: () async {
                  await ref
                      .read(notificationRepositoryProvider)
                      .deleteHistoryItem(item.id);
                  ref.invalidate(notificationHistoryProvider);
                  ref.invalidate(unreadNotificationCountProvider);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openItem(
    BuildContext context,
    WidgetRef ref,
    NotificationRecord item,
  ) async {
    await ref
        .read(notificationRepositoryProvider)
        .markHistoryRead(item.id);
    ref.invalidate(notificationHistoryProvider);
    ref.invalidate(unreadNotificationCountProvider);

    final type = NotificationPayload.decode(item.payloadForNavigation);
    if (type != null && context.mounted) {
      context.push(NotificationPayload.routeFor(type));
    }
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.record,
    required this.onTap,
    required this.onDismiss,
  });

  final NotificationRecord record;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: colors.errorContainer,
        child: Icon(Icons.delete, color: colors.onErrorContainer),
      ),
      child: Material(
        color: record.isRead
            ? colors.surfaceContainerHighest
            : colors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconForSource(record.source), color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: record.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_sourceLabel(record.source)} · ${DashboardFormatters.relativeTime(record.receivedAt)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (!record.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForSource(NotificationSource source) => switch (source) {
        NotificationSource.push => Icons.cloud_outlined,
        NotificationSource.local => Icons.notifications_active_outlined,
        NotificationSource.scheduled => Icons.schedule_outlined,
      };

  String _sourceLabel(NotificationSource source) => switch (source) {
        NotificationSource.push => 'Push server',
        NotificationSource.local => 'Trong app',
        NotificationSource.scheduled => 'Lịch nhắc',
      };
}
