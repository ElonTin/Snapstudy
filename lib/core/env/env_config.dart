import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to environment variables loaded from `.env`.
class EnvConfig {
  EnvConfig._();

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000';

  static String get environment => dotenv.env['ENV'] ?? 'development';

  static bool get isDevelopment => environment == 'development';

  static bool get isProduction => environment == 'production';

  static bool get enableFirebase =>
      (dotenv.env['ENABLE_FIREBASE'] ?? 'false').toLowerCase() == 'true';

  static String get appName => dotenv.env['APP_NAME'] ?? 'SNAPSTUDY';

  static bool get authDevMode =>
      (dotenv.env['AUTH_DEV_MODE'] ?? 'false').toLowerCase() == 'true';

  static String? get googleServerClientId {
    final value = dotenv.env['GOOGLE_SERVER_CLIENT_ID'];
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  /// Phase 7 — OpenCV preprocessing before OCR (Phase 8).
  static bool get enablePreprocessing =>
      (dotenv.env['ENABLE_PREPROCESSING'] ?? 'true').toLowerCase() == 'true';

  /// Phase 8 — allow mock OCR on desktop (Windows tests). Ignored on Android/iOS.
  static bool get ocrDevMode =>
      (dotenv.env['OCR_DEV_MODE'] ?? 'false').toLowerCase() == 'true';

  /// OCR engine: `gemini` (vision API), `mlkit` (on-device), `auto` (gemini if key set).
  static String get ocrEngine =>
      (dotenv.env['OCR_ENGINE'] ?? 'auto').trim().toLowerCase();

  /// Force mock OCR even on phone (debug only).
  static bool get ocrForceMock =>
      (dotenv.env['OCR_FORCE_MOCK'] ?? 'false').toLowerCase() == 'true';

  /// Phase 9 — Google Gemini API.
  static String get geminiBaseUrl =>
      dotenv.env['GEMINI_BASE_URL'] ??
      'https://generativelanguage.googleapis.com';

  static String get geminiModel =>
      dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';

  static String? get geminiApiKey {
    final value = dotenv.env['GEMINI_API_KEY'];
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  /// True when [GEMINI_API_KEY] is set — real Gemini calls are allowed.
  static bool get isGeminiConfigured =>
      geminiApiKey != null && geminiApiKey!.isNotEmpty;

  static bool _flag(String key, {bool defaultValue = false}) =>
      (dotenv.env[key] ?? defaultValue.toString()).toLowerCase() == 'true';

  static bool get aiSummaryDevMode => _flag('AI_SUMMARY_DEV_MODE');

  /// Force mock output even when an API key exists (offline UI tests).
  static bool get aiSummaryForceMock => _flag('AI_SUMMARY_FORCE_MOCK');

  /// Mock when no API key, or [AI_SUMMARY_FORCE_MOCK]=true. Key present → Gemini.
  static bool get useMockAiSummary =>
      !isGeminiConfigured || aiSummaryForceMock;

  /// Phase 10 — flashcard generation (shares Gemini key with summary).
  static bool get flashcardsDevMode => _flag('FLASHCARDS_DEV_MODE');

  static bool get flashcardsForceMock => _flag('FLASHCARDS_FORCE_MOCK');

  static bool get useMockFlashcards =>
      !isGeminiConfigured || flashcardsForceMock;

  /// Phase 12 — MCQ quiz generation (shares Gemini key).
  static bool get quizDevMode => _flag('QUIZ_DEV_MODE');

  static bool get quizForceMock => _flag('QUIZ_FORCE_MOCK');

  static bool get useMockQuiz => !isGeminiConfigured || quizForceMock;

  /// Phase 13 — knowledge mindmap graph.
  static bool get mindmapDevMode => _flag('MINDMAP_DEV_MODE');

  static bool get mindmapForceMock => _flag('MINDMAP_FORCE_MOCK');

  static bool get useMockMindmap =>
      !isGeminiConfigured || mindmapForceMock;

  /// Phase 14 — push via FCM when Firebase is configured.
  static bool get enableFcm =>
      enableFirebase &&
      (dotenv.env['ENABLE_FCM'] ?? 'true').toLowerCase() == 'true';

  /// POST FCM token to backend for server-initiated push.
  static bool get enablePushRegistration =>
      (dotenv.env['ENABLE_PUSH_REGISTRATION'] ?? 'true').toLowerCase() ==
      'true';

  static String get pushRegisterPath =>
      dotenv.env['PUSH_REGISTER_PATH'] ?? '/api/notifications/devices';
}
