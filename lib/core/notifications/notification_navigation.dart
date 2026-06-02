import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/notifications/notification_payload.dart';
import 'package:snapstudy/core/utils/logger.dart';

/// Routes notification taps via [GoRouter].
abstract final class NotificationNavigation {
  static GoRouter? _router;
  static Future<void> Function(String? payload)? onPayloadOpened;

  static void bind(
    GoRouter router, {
    Future<void> Function(String? payload)? onOpened,
  }) {
    _router = router;
    onPayloadOpened = onOpened;
  }

  static Future<void> handlePayload(String? payload) async {
    await onPayloadOpened?.call(payload);

    final type = NotificationPayload.decode(payload);
    if (type == null || _router == null) return;

    final path = NotificationPayload.routeFor(type);
    try {
      _router!.push(path);
    } catch (e, st) {
      AppLogger.warning('Notification navigation failed', e);
      AppLogger.debug('Notification nav stack', e, st);
    }
  }
}
