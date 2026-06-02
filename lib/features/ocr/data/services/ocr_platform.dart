import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:snapstudy/core/env/env_config.dart';

/// Whether Google ML Kit text recognition can run on this device.
abstract final class OcrPlatform {
  static bool get supportsMlKit {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Mock/sample OCR — only when ML Kit is unavailable or explicitly forced.
  static bool get useMockRecognizer {
    if (EnvConfig.ocrForceMock) return true;
    if (supportsMlKit) return false;
    return EnvConfig.ocrDevMode;
  }

  static bool get useGeminiVision {
    if (useMockRecognizer) return false;
    final engine = EnvConfig.ocrEngine;
    if (engine == 'mlkit') return false;
    if (engine == 'gemini') return EnvConfig.isGeminiConfigured;
    // auto
    return EnvConfig.isGeminiConfigured;
  }

  static bool get useMlKitFallback =>
      !useMockRecognizer && supportsMlKit && useGeminiVision;

  static String get engineLabel {
    if (useMockRecognizer) return 'Mẫu (dev)';
    if (useGeminiVision && useMlKitFallback) {
      return 'Gemini Vision + ML Kit';
    }
    if (useGeminiVision) return 'Gemini Vision';
    if (supportsMlKit) return 'ML Kit';
    return 'Không khả dụng';
  }
}
