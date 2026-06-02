import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/notifications/data/models/notification_record_model.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_record.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_source.dart';

void main() {
  test('NotificationRecordModel round-trip', () {
    final entity = NotificationRecord(
      id: 'n1',
      title: 'Ôn tập',
      body: '3 thẻ due',
      payloadType: 'review',
      source: NotificationSource.push,
      receivedAt: DateTime(2025, 6, 1, 19),
      remoteMessageId: 'fcm-abc',
      data: const {'type': 'review'},
    );

    final json = NotificationRecordModel.fromEntity(entity).toJson();
    final restored = NotificationRecordModel.fromJson(json).toEntity();

    expect(restored.id, entity.id);
    expect(restored.remoteMessageId, 'fcm-abc');
    expect(restored.isRead, false);
  });
}
