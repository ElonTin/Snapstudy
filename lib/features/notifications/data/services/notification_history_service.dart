import 'package:snapstudy/core/notifications/notification_payload.dart';
import 'package:snapstudy/features/notifications/data/datasources/notification_history_datasource.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_record.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_source.dart';

/// Records notifications into local inbox history.
class NotificationHistoryService {
  NotificationHistoryService({NotificationHistoryDataSource? dataSource})
      : _store = dataSource ?? NotificationHistoryDataSource();

  final NotificationHistoryDataSource _store;
  List<NotificationRecord> getAll() => _store.readAll();

  int unreadCount() => _store.unreadCount();

  Future<NotificationRecord> record({
    required String title,
    required String body,
    required String payloadType,
    required NotificationSource source,
    String? remoteMessageId,
    Map<String, String>? data,
  }) async {
    final record = NotificationRecord(
      id: 'n_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      payloadType: _normalizePayloadType(payloadType),
      source: source,
      receivedAt: DateTime.now(),
      remoteMessageId: remoteMessageId,
      data: data ?? const {},
    );
    return _store.append(record);
  }

  Future<void> markRead(String id) => _store.markRead(id);

  Future<void> markAllRead() => _store.markAllRead();

  Future<void> delete(String id) => _store.delete(id);

  Future<void> clear() => _store.clear();

  /// Marks items matching navigation payload as read.
  Future<void> markOpenedByPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    final base = payload.split(':').first;
    for (final r in _store.readAll()) {
      if (!r.isRead && r.payloadForNavigation.startsWith(base)) {
        await _store.markRead(r.id);
      }
    }
  }

  String _normalizePayloadType(String raw) {
    final base = raw.split(':').first;
    if (NotificationPayload.decode(base) != null) return base;
    return NotificationPayload.push;
  }
}
