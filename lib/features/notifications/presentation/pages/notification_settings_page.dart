import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_preferences.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/features/notifications/presentation/providers/notification_providers.dart';

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
        loading: () => const AppLoading(fullScreen: true),
        error: (e, _) => Center(child: Text('$e')),
        data: (prefs) {
          final draft = _draft ?? prefs;

          return ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: const Text('Hộp thông báo'),
                subtitle: const Text('Lịch sử push & nhắc local'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RoutePaths.notificationHistory),
              ),
              const Divider(),
              if (EnvConfig.enableFcm) ...[
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Firebase Cloud Messaging'),
                  subtitle: Text(
                    draft.fcmToken != null
                        ? 'Token đã lưu — đăng ký server khi có API'
                        : 'Bật ENABLE_FIREBASE + google-services',
                  ),
                ),
                if (EnvConfig.enablePushRegistration)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
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
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Đăng ký push lên server'),
                    ),
                  ),
                const Divider(),
              ],
              SwitchListTile(
                title: const Text('Nhắc ôn tập (SRS)'),
                subtitle: const Text('Hàng ngày khi còn thẻ due'),
                value: draft.reviewRemindersEnabled,
                onChanged: _saving
                    ? null
                    : (v) => setState(
                          () => _draft = draft.copyWith(
                            reviewRemindersEnabled: v,
                          ),
                        ),
              ),
              ListTile(
                title: const Text('Giờ nhắc ôn'),
                trailing: Text(_timeLabel(draft.reviewHour, draft.reviewMinute)),
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
              const Divider(),
              SwitchListTile(
                title: const Text('Nhắc streak'),
                subtitle: const Text('Sáng — nếu chưa ôn trong ngày'),
                value: draft.streakRemindersEnabled,
                onChanged: _saving
                    ? null
                    : (v) => setState(
                          () => _draft =
                              draft.copyWith(streakRemindersEnabled: v),
                        ),
              ),
              ListTile(
                title: const Text('Giờ nhắc streak'),
                trailing:
                    Text(_timeLabel(draft.streakHour, draft.streakMinute)),
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
              const Divider(),
              SwitchListTile(
                title: const Text('Nhắc buổi học'),
                subtitle: const Text(
                  'Buổi đang mở hoặc chờ OCR/AI',
                ),
                value: draft.sessionRemindersEnabled,
                onChanged: _saving
                    ? null
                    : (v) => setState(
                          () => _draft =
                              draft.copyWith(sessionRemindersEnabled: v),
                        ),
              ),
              ListTile(
                title: const Text('Giờ nhắc buổi học'),
                trailing:
                    Text(_timeLabel(draft.sessionHour, draft.sessionMinute)),
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
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving || _draft == null
                    ? null
                    : () => _save(_draft!),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Đang lưu...' : 'Lưu & cập nhật lịch'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
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
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Xin quyền & đồng bộ lại'),
              ),
            ],
          );
        },
      ),
    );
  }
}
