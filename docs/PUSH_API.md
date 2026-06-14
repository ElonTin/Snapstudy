# Server Push API (SNAPSTUDY)

Ứng dụng đăng ký FCM token qua endpoint sau khi Firebase khởi tạo và khi token refresh.

## Chạy backend dev (hướng C)

```powershell
cd server/SnapStudy.Api
dotnet run
```

API lắng nghe `http://0.0.0.0:5000` — điện thoại thật truy cập qua IP LAN của PC.

Trong `.env` Flutter:

```env
API_BASE_URL=http://192.168.x.x:5000
ENABLE_FIREBASE=true
ENABLE_FCM=true
ENABLE_PUSH_REGISTRATION=true
```

Kiểm tra:

```powershell
curl http://localhost:5000/health
curl http://localhost:5000/api/notifications/devices
```

Token đăng ký được lưu tại `server/SnapStudy.Api/data/device-registrations.json`.

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

## Firebase Admin (gửi push thật)

**Không commit file service account.** Lưu JSON tải từ Firebase Console tại:

```
server/SnapStudy.Api/secrets/firebase-service-account.json
```

Hoặc đặt biến môi trường:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="D:\path\to\firebase-service-account.json"
```

> Nếu private key đã lộ (chat, git, screenshot): Firebase Console → Service accounts → **Generate new private key** → xóa key cũ.

Gửi thử tới mọi thiết bị đã đăng ký:

```powershell
Invoke-RestMethod `
  -Uri http://localhost:5000/api/notifications/send `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"title":"SNAPSTUDY","body":"Bạn có thẻ cần ôn hôm nay","type":"review"}'
```

Gửi tới một token cụ thể:

```json
{
  "title": "SNAPSTUDY",
  "body": "Test push",
  "type": "push",
  "fcmToken": "<token>"
}
```

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
