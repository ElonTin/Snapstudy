/// Global app-level constants (non-API, non-route).
abstract final class AppConstants {
  static const String appName = 'SNAPSTUDY';
  static const String appSlogan =
      'Smart Capture, Active Learning – Transform classroom photos into structured knowledge.';

  static const Duration splashDuration = Duration(milliseconds: 1800);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  static const Duration snackBarDuration = Duration(seconds: 3);

  static const double maxContentWidth = 600;
  static const double defaultPadding = 20;
  static const double compactPadding = 12;
  static const double sectionSpacing = 28;
  static const double defaultRadius = 16;
  static const double smallRadius = 12;
  static const double largeRadius = 24;
  static const double cardElevation = 0;
}
