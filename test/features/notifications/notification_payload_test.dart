import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/notifications/notification_payload.dart';
import 'package:snapstudy/core/routing/route_paths.dart';

void main() {
  test('decode review payload routes to review queue', () {
    final type = NotificationPayload.decode(NotificationPayload.review);
    expect(type, NotificationPayloadType.review);
    expect(
      NotificationPayload.routeFor(type!),
      RoutePaths.reviewQueue,
    );
  });

  test('decode streak payload routes to home', () {
    final type = NotificationPayload.decode(NotificationPayload.streak);
    expect(NotificationPayload.routeFor(type!), RoutePaths.home);
  });
}
