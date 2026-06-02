# Server Push API (SNAPSTUDY)

Ứng dụng đăng ký FCM token qua endpoint sau khi Firebase khởi tạo và khi token refresh.

## Đăng ký thiết bị

`POST {API_BASE_URL}/api/notifications/devices`

Headers (tuỳ chọn):

```
Authorization: Bearer <access_token>
Content-Type: application/json
```

Body:

```json
{
  "fcmToken": "<firebase_messaging_token>",
  "platform": "android | ios | web",
  "userId": "<optional user id>"
}
```

Response `200` hoặc `201` — thành công.

Nếu backend chưa có endpoint (`404`), app vẫn chạy bình thường (chỉ log cảnh báo).

## Gửi push từ server (FCM HTTP v1)

Payload `data` nên có:

```json
{
  "type": "review | streak | session | push"
}
```

`notification.title` / `notification.body` hiển thị trên tray.

Ví dụ nhắc ôn:

```json
{
  "notification": {
    "title": "SNAPSTUDY",
    "body": "Bạn có 12 thẻ cần ôn hôm nay"
  },
  "data": {
    "type": "review"
  }
}
```

## Lịch sử trên app

Mọi push/local/scheduled được lưu tối đa 200 mục trong Hive (`notification_history`).
Hộp thông báo: **Cài đặt → Hộp thông báo** hoặc icon chuông trên Home.
