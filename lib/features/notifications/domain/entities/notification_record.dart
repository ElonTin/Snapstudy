import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_source.dart';

/// One inbox item (push or local).
class NotificationRecord extends Equatable {
  const NotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.payloadType,
    required this.source,
    required this.receivedAt,
    this.isRead = false,
    this.remoteMessageId,
    this.data = const {},
  });

  final String id;
  final String title;
  final String body;

  /// Matches [NotificationPayload] type name (review, streak, session, push).
  final String payloadType;
  final NotificationSource source;
  final DateTime receivedAt;
  final bool isRead;
  final String? remoteMessageId;
  final Map<String, String> data;

  String get payloadForNavigation =>
      data['routePayload'] ?? payloadType;

  NotificationRecord copyWith({
    bool? isRead,
  }) {
    return NotificationRecord(
      id: id,
      title: title,
      body: body,
      payloadType: payloadType,
      source: source,
      receivedAt: receivedAt,
      isRead: isRead ?? this.isRead,
      remoteMessageId: remoteMessageId,
      data: data,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        payloadType,
        source,
        receivedAt,
        isRead,
        remoteMessageId,
        data,
      ];
}
