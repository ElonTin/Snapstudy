import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/firebase/firebase_service.dart';
import 'package:snapstudy/core/notifications/notification_channels.dart';
import 'package:snapstudy/core/notifications/notification_navigation.dart';
import 'package:snapstudy/core/notifications/notification_payload.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/features/notifications/data/datasources/notification_prefs_datasource.dart';
import 'package:snapstudy/features/notifications/data/services/local_notification_service.dart';
import 'package:snapstudy/features/notifications/data/services/notification_history_service.dart';
import 'package:snapstudy/features/notifications/data/services/push_registration_api.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_source.dart';

/// Firebase Cloud Messaging — optional when Firebase is enabled.
class FcmService {
  FcmService({
    required LocalNotificationService local,
    required NotificationHistoryService history,
    NotificationPrefsDataSource? prefs,
    PushRegistrationApi? pushApi,
    this.resolveAuthBearer,
    this.resolveUserId,
  })  : _local = local,
        _history = history,
        _prefs = prefs ?? NotificationPrefsDataSource(),
        _pushApi = pushApi ?? PushRegistrationApi();

  final LocalNotificationService _local;
  final NotificationHistoryService _history;
  final NotificationPrefsDataSource _prefs;
  final PushRegistrationApi _pushApi;
  final Future<String?> Function()? resolveAuthBearer;
  final Future<String?> Function()? resolveUserId;

  Future<void> initialize() async {
    if (!EnvConfig.enableFcm || !FirebaseService.isInitialized) {
      AppLogger.info('FCM skipped — Firebase not active');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null) {
      await _prefs.saveFcmToken(token);
      await _registerWithServer(token);
    }

    messaging.onTokenRefresh.listen((t) async {
      await _prefs.saveFcmToken(t);
      await _registerWithServer(t);
    });

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      await _handleRemoteMessage(initial, fromTap: true);
    }
  }

  Future<void> _registerWithServer(String token) async {
    final bearer = await resolveAuthBearer?.call();
    final userId = await resolveUserId?.call();
    final result = await _pushApi.registerDevice(
      fcmToken: token,
      userId: userId,
      authBearer: bearer,
    );
    result.fold(
      onSuccess: (_) => AppLogger.info('Server push registration OK'),
      onFailure: (f) =>
          AppLogger.warning('Server push registration failed: ${f.message}'),
    );
  }

  Future<void> registerTokenWithServer() async {
    final token = _prefs.read().fcmToken;
    if (token == null || token.isEmpty) return;
    await _registerWithServer(token);
  }

  void _onForegroundMessage(RemoteMessage message) {
    _handleRemoteMessage(message, fromTap: false);
  }

  void _onMessageOpened(RemoteMessage message) {
    _handleRemoteMessage(message, fromTap: true);
  }

  Future<void> _handleRemoteMessage(
    RemoteMessage message, {
    required bool fromTap,
  }) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] as String? ?? NotificationPayload.push;
    final payload = type;

    await _history.record(
      title: notification.title ?? 'SNAPSTUDY',
      body: notification.body ?? '',
      payloadType: payload,
      source: NotificationSource.push,
      remoteMessageId: message.messageId,
      data: message.data.map((k, v) => MapEntry(k, '$v')),
    );

    if (fromTap) {
      await NotificationNavigation.handlePayload(payload);
      return;
    }

    await _local.show(
      id: message.hashCode & 0x7FFFFFFF,
      title: notification.title ?? 'SNAPSTUDY',
      body: notification.body ?? '',
      channelId: NotificationChannels.push,
      payload: payload,
    );
  }
}
