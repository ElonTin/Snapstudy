# SNAPSTUDY — Test suite (Phase 16)

## Layout

| Thư mục | Loại | Mục đích |
|---------|------|----------|
| `test/core/` | Unit | Cache, guards, `Result` |
| `test/features/api/` | API | Dio + Gemini, push registration |
| `test/features/<feature>/` | Unit + Repository | Parser, domain, Hive repos |
| `test/widgets/` | Widget | UI components với Riverpod overrides |
| `test/helpers/` | Fixtures | Hive, sessions, mock Dio/Gemini |

## Chạy

```bash
flutter test
flutter test test/features/api
flutter test test/widgets
```

## Quy ước

- **Repository tests**: `initHiveForRepositoryTests()` + fixtures trong `session_fixtures.dart`
- **API tests**: `createMockDio()` — không gọi mạng thật
- **Widget tests**: `initTestEnvironment(withHive: true)` + override providers
- Sau mỗi test ghi session: `PerformanceCaches.invalidateAll()` (qua helper)

## Mock AI

Mặc định `.env` test bật `*_DEV_MODE=true` để repository dùng mock generators, không cần Gemini thật.
