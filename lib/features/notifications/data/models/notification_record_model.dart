import 'package:snapstudy/features/notifications/domain/entities/notification_record.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_source.dart';

class NotificationRecordModel {
  const NotificationRecordModel({
    required this.id,
    required this.title,
    required this.body,
    required this.payloadType,
    required this.source,
    required this.receivedAt,
    required this.isRead,
    this.remoteMessageId,
    this.data = const {},
  });

  factory NotificationRecordModel.fromJson(Map<String, dynamic> json) {
    return NotificationRecordModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      payloadType: json['payloadType'] as String,
      source: NotificationSource.values.byName(json['source'] as String),
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      remoteMessageId: json['remoteMessageId'] as String?,
      data: (json['data'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, '$v'),
          ) ??
          {},
    );
  }

  final String id;
  final String title;
  final String body;
  final String payloadType;
  final NotificationSource source;
  final DateTime receivedAt;
  final bool isRead;
  final String? remoteMessageId;
  final Map<String, String> data;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'payloadType': payloadType,
        'source': source.name,
        'receivedAt': receivedAt.toIso8601String(),
        'isRead': isRead,
        if (remoteMessageId != null) 'remoteMessageId': remoteMessageId,
        'data': data,
      };

  NotificationRecord toEntity() => NotificationRecord(
        id: id,
        title: title,
        body: body,
        payloadType: payloadType,
        source: source,
        receivedAt: receivedAt,
        isRead: isRead,
        remoteMessageId: remoteMessageId,
        data: data,
      );

  static NotificationRecordModel fromEntity(NotificationRecord r) =>
      NotificationRecordModel(
        id: r.id,
        title: r.title,
        body: r.body,
        payloadType: r.payloadType,
        source: r.source,
        receivedAt: r.receivedAt,
        isRead: r.isRead,
        remoteMessageId: r.remoteMessageId,
        data: r.data,
      );
}
