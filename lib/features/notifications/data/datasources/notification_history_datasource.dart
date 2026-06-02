import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/features/notifications/data/models/notification_record_model.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_record.dart';

class NotificationHistoryDataSource {
  static const _maxItems = 200;

  List<NotificationRecord> readAll() {
    final raw = HiveService.settingsBox.get(StorageKeys.notificationHistory);
    if (raw is! List) return [];

    return raw
        .map((e) => NotificationRecordModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .map((m) => m.toEntity())
        .toList()
      ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }

  Future<NotificationRecord> append(NotificationRecord record) async {
    final list = readAll();

    if (record.remoteMessageId != null) {
      final dup = list.any((r) => r.remoteMessageId == record.remoteMessageId);
      if (dup) return record;
    }

    list.insert(0, record);
    final trimmed = list.take(_maxItems).toList();
    await _persist(trimmed);
    return record;
  }

  Future<void> markRead(String id) async {
    final list = readAll();
    final updated = list
        .map((r) => r.id == id ? r.copyWith(isRead: true) : r)
        .toList();
    await _persist(updated);
  }

  Future<void> markAllRead() async {
    final updated = readAll().map((r) => r.copyWith(isRead: true)).toList();
    await _persist(updated);
  }

  Future<void> delete(String id) async {
    final updated = readAll().where((r) => r.id != id).toList();
    await _persist(updated);
  }

  Future<void> clear() async {
    await HiveService.settingsBox.delete(StorageKeys.notificationHistory);
  }

  int unreadCount() => readAll().where((r) => !r.isRead).length;

  Future<void> _persist(List<NotificationRecord> list) async {
    final json = list
        .map((r) => NotificationRecordModel.fromEntity(r).toJson())
        .toList();
    await HiveService.settingsBox.put(StorageKeys.notificationHistory, json);
  }
}
