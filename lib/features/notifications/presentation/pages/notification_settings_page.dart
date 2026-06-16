import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_preferences.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/features/notifications/presentation/providers/notification_providers.dart';
import 'package:snapstudy/core/constants/route_names.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  NotificationPreferences? _draft;
  var _saving = false;

  Future<void> _save(NotificationPreferences prefs) async {
    setState(() => _saving = true);
    final result = await ref
        .read(notificationRepositoryProvider)
        .savePreferences(prefs);
    setState(() => _saving = false);
    if (mounted) {
      result.fold(
        onSuccess: (_) {
          ref.invalidate(notificationPreferencesProvider);
          context.showSnack('Đã lưu cài đặt thông báo');
        },
        onFailure: (f) => context.showSnack(f.message, isError: true),
      );
    }
  }

  String _timeLabel(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Future<void> _pickTime({
    required int hour,
    required int minute,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: prefsAsync.when(
        loading: () => const AppLoading(fullScreen: true, useSkeleton: true),
        error: (e, _) => Center(child: Text('$e')),
        data: (prefs) {
          final draft = _draft ?? prefs;

          return ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              AppCard(
                onTap: () => context.push(RoutePaths.notificationHistory),
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(
                    Icons.inbox_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Hộp thông báo'),
                  subtitle: const Text('Lịch sử push & nhắc local'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 20),
              if (EnvConfig.enableFcm) ...[
                const AppSectionHeader(
                  title: 'Firebase Cloud Messaging',
                  subtitle: 'Đăng ký push từ server',
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              draft.fcmToken != null
                                  ? 'Token đã lưu — đăng ký server khi có API'
                                  : 'Bật ENABLE_FIREBASE + google-services',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (EnvConfig.enablePushRegistration) ...[
                        const SizedBox(height: 14),
                        AppButton(
                          label: 'Đăng ký push lên server',
                          variant: AppButtonVariant.outline,
                          icon: Icons.cloud_upload_outlined,
                          expand: true,
                          onPressed: _saving
                              ? null
                              : () async {
                                  await ref
                                      .read(notificationRepositoryProvider)
                                      .registerPushWithServer();
                                  if (context.mounted) {
                                    context.showSnack(
                                      'Đã gửi token lên server (nếu endpoint sẵn sàng)',
                                    );
                                  }
                                },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const AppSectionHeader(
                title: 'Nhắc ôn tập (SRS)',
                subtitle: 'Hàng ngày khi còn thẻ due',
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Bật nhắc ôn tập'),
                      value: draft.reviewRemindersEnabled,
                      onChanged: _saving
                          ? null
                          : (v) => setState(
                                () => _draft = draft.copyWith(
                                  reviewRemindersEnabled: v,
                                ),
                              ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Giờ nhắc ôn'),
                      trailing: Text(
                        _timeLabel(draft.reviewHour, draft.reviewMinute),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      onTap: _saving
                          ? null
                          : () => _pickTime(
                                hour: draft.reviewHour,
                                minute: draft.reviewMinute,
                                onPicked: (t) => setState(
                                  () => _draft = draft.copyWith(
                                    reviewHour: t.hour,
                                    reviewMinute: t.minute,
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const AppSectionHeader(
                title: 'Nhắc streak',
                subtitle: 'Sáng — nếu chưa ôn trong ngày',
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Bật nhắc streak'),
                      value: draft.streakRemindersEnabled,
                      onChanged: _saving
                          ? null
                          : (v) => setState(
                                () => _draft =
                                    draft.copyWith(streakRemindersEnabled: v),
                              ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Giờ nhắc streak'),
                      trailing: Text(
                        _timeLabel(draft.streakHour, draft.streakMinute),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      onTap: _saving
                          ? null
                          : () => _pickTime(
                                hour: draft.streakHour,
                                minute: draft.streakMinute,
                                onPicked: (t) => setState(
                                  () => _draft = draft.copyWith(
                                    streakHour: t.hour,
                                    streakMinute: t.minute,
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const AppSectionHeader(
                title: 'Nhắc buổi học',
                subtitle: 'Buổi đang mở hoặc chờ OCR/AI',
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Bật nhắc buổi học'),
                      value: draft.sessionRemindersEnabled,
                      onChanged: _saving
                          ? null
                          : (v) => setState(
                                () => _draft =
                                    draft.copyWith(sessionRemindersEnabled: v),
                              ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Giờ nhắc buổi học'),
                      trailing: Text(
                        _timeLabel(draft.sessionHour, draft.sessionMinute),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      onTap: _saving
                          ? null
                          : () => _pickTime(
                                hour: draft.sessionHour,
                                minute: draft.sessionMinute,
                                onPicked: (t) => setState(
                                  () => _draft = draft.copyWith(
                                    sessionHour: t.hour,
                                    sessionMinute: t.minute,
                                  ),
                                ),
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: _saving ? 'Đang lưu...' : 'Lưu & cập nhật lịch',
                variant: AppButtonVariant.primary,
                icon: Icons.save_outlined,
                expand: true,
                isLoading: _saving,
                onPressed: _saving || _draft == null
                    ? null
                    : () => _save(_draft!),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Xin quyền & đồng bộ lại',
                variant: AppButtonVariant.outline,
                icon: Icons.notifications_active_outlined,
                expand: true,
                onPressed: _saving
                    ? null
                    : () async {
                        await ref
                            .read(notificationRepositoryProvider)
                            .requestPermission();
                        await ref
                            .read(notificationRepositoryProvider)
                            .syncScheduledReminders();
                        if (context.mounted) {
                          context.showSnack('Đã làm mới quyền & lịch nhắc');
                        }
                      },
              ),
              const SizedBox(height: 28),

              // ── Hỗ trợ & phản hồi ────────────────────────────────────
              const AppSectionHeader(
                title: 'Hỗ trợ & phản hồi',
                subtitle: 'Gửi ý kiến đến nhà phát triển',
              ),
              const SizedBox(height: 8),
              AppCard(
                onTap: () => context.pushNamed(RouteNames.feedback),
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiaryContainer
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.feedback_outlined,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 22,
                    ),
                  ),
                  title: const Text('Gửi phản hồi'),
                  subtitle: const Text(
                    'Báo lỗi, góp ý hoặc khen ngợi ứng dụng',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
