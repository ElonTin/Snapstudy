/// URL path constants for GoRouter.
abstract final class RoutePaths {
  static const String splash = '/';
  static const String home = '/home';
  static const String notificationSettings = '/settings/notifications';
  static const String notificationHistory = '/settings/notifications/history';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String subjects = '/subjects';
  static const String subjectCreate = '/subjects/new';

  static String subjectEditPath(String id) => '/subjects/$id/edit';

  static const String sessionStart = '/sessions/start';
  static const String sessionActive = '/sessions/active';
  static const String cameraCapture = '/camera';
  static const String galleryImport = '/import/gallery';
  static const String sessionsHistory = '/sessions';
  static const String ingestProgress = '/ingest/progress';

  static String ingestProgressPath({String? sessionId}) {
    if (sessionId != null && sessionId.isNotEmpty) {
      return '$ingestProgress?sessionId=$sessionId';
    }
    return ingestProgress;
  }

  static String sessionDetailPath(String id) => '/sessions/$id';

  static String flashcardStudyPath(String sessionId, {bool weakOnly = false}) {
    final base = '/sessions/$sessionId/flashcards';
    return weakOnly ? '$base?weakOnly=true' : base;
  }

  static String quizPlayPath(String sessionId) => '/sessions/$sessionId/quiz';

  static String mindmapViewPath(String sessionId) =>
      '/sessions/$sessionId/mindmap';

  static const String reviewQueue = '/reviews';

  static String reviewQueuePath({String? sessionId}) =>
      sessionId != null && sessionId.isNotEmpty
          ? '$reviewQueue?sessionId=$sessionId'
          : reviewQueue;

  static String weakAreasPath(String sessionId) =>
      '/sessions/$sessionId/weak-areas';
}
