import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/storage/hive_boxes.dart';
import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_session.dart';
import 'package:snapstudy/features/auth/domain/entities/auth_tokens.dart';
import 'package:snapstudy/features/auth/domain/entities/user.dart';

bool _initialized = false;

/// Initializes test environment (dotenv + optional Hive).
Future<void> initTestEnvironment({bool withHive = false}) async {
  if (_initialized) return;

  GoogleFonts.config.allowRuntimeFetching = false;

  dotenv.testLoad(
    fileInput: '''
API_BASE_URL=http://localhost:5000
ENV=test
ENABLE_FIREBASE=false
APP_NAME=SNAPSTUDY
AUTH_DEV_MODE=true
GOOGLE_SERVER_CLIENT_ID=
GEMINI_API_KEY=
GEMINI_MODEL=gemini-2.0-flash
AI_SUMMARY_FORCE_MOCK=true
FLASHCARDS_FORCE_MOCK=true
QUIZ_FORCE_MOCK=true
MINDMAP_FORCE_MOCK=true
ENABLE_PUSH_REGISTRATION=true
PUSH_REGISTER_PATH=/api/notifications/devices
DASHBOARD_CACHE_TTL_SECONDS=45
SESSION_LIST_CACHE_TTL_SECONDS=30
''',
  );

  if (withHive) {
    final dir = Directory.systemTemp.createTempSync('snapstudy_test_hive_');
    Hive.init(dir.path);
    HiveService.settingsBox = await Hive.openBox(HiveBoxes.settings);
    HiveService.cacheBox = await Hive.openBox(HiveBoxes.cache);
    HiveService.subjectsBox = await Hive.openBox(HiveBoxes.subjects);
    HiveService.sessionsBox = await Hive.openBox(HiveBoxes.sessions);
    await HiveService.settingsBox.put(StorageKeys.onboardingCompleted, true);
  }

  _initialized = true;
}

AuthSession testAuthSession() => const AuthSession(
      user: User(
        id: 'test-1',
        email: 'test@snapstudy.app',
        displayName: 'Test User',
      ),
      tokens: AuthTokens(
        accessToken: 'test_token',
        refreshToken: 'test_refresh',
      ),
    );
