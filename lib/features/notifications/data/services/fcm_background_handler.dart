import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:snapstudy/core/notifications/notification_payload.dart';
import 'package:snapstudy/core/storage/hive_boxes.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/features/notifications/data/services/notification_history_service.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_source.dart';

/// Background FCM handler — persists push to notification history.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await Hive.initFlutter();
    await Hive.openBox(HiveBoxes.settings);

    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] as String? ?? NotificationPayload.push;
    final history = NotificationHistoryService();
    await history.record(
      title: notification.title ?? 'SNAPSTUDY',
      body: notification.body ?? '',
      payloadType: type,
      source: NotificationSource.push,
      remoteMessageId: message.messageId,
      data: message.data.map((k, v) => MapEntry(k, '$v')),
    );

    AppLogger.info('FCM background saved to history: ${message.messageId}');
  } catch (e, st) {
    AppLogger.warning('FCM background handler failed', e);
    AppLogger.debug('FCM background stack', e, st);
  }
}
