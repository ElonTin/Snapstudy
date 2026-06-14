/// Camera module tuning (compression, overlay).
abstract final class CameraConstants {
  static const int compressMaxEdge = 3200;
  static const int compressQuality = 95;

  /// Used when re-encoding images before cloud OCR.
  static const int ocrMaxEdge = 2560;
  static const int ocrJpegQuality = 92;

  /// Document crop guide — fraction of preview (width, height).
  static const double cropGuideWidthFraction = 0.88;
  static const double cropGuideHeightFraction = 0.62;
  static const double cropGuideCornerRadius = 12;
  static const double cropGuideStrokeWidth = 2.5;
}
