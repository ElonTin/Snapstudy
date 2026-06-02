import 'package:snapstudy/core/routing/route_paths.dart';

/// Deep-link payload stored on notification tap.
enum NotificationPayloadType { review, streak, session, push }

abstract final class NotificationPayload {
  static const review = 'review';
  static const streak = 'streak';
  static const session = 'session';
  static const push = 'push';

  static String encode(NotificationPayloadType type) => type.name;

  static NotificationPayloadType? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final base = raw.contains(':') ? raw.split(':').first : raw;
    return NotificationPayloadType.values
        .where((t) => t.name == base)
        .firstOrNull;
  }

  static String routeFor(NotificationPayloadType type) => switch (type) {
        NotificationPayloadType.review => RoutePaths.reviewQueue,
        NotificationPayloadType.streak => RoutePaths.home,
        NotificationPayloadType.session => RoutePaths.sessionActive,
        NotificationPayloadType.push => RoutePaths.home,
      };
}
