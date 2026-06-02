import 'dart:convert';

/// Normalizes and validates JSON text from Gemini.
abstract final class GeminiJsonUtils {
  GeminiJsonUtils._();

  static String normalize(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text
          .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }
    return text;
  }

  static bool isValidJsonObject(String raw) {
    try {
      final decoded = jsonDecode(normalize(raw));
      return decoded is Map<String, dynamic>;
    } catch (_) {
      return false;
    }
  }
}
