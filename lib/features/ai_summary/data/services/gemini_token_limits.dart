/// Per-feature token budgets tuned for Gemini free tier (gemini-2.5-flash).
enum GeminiAiFeature {
  ocr,
  summary,
  flashcards,
  quiz,
  mindmap,
}

abstract final class GeminiTokenLimits {
  GeminiTokenLimits._();

  /// Rough chars-per-token for Vietnamese + JSON prompts.
  static const int charsPerTokenEstimate = 4;

  /// Max OCR text injected into the prompt (characters).
  static int maxInputOcrChars(GeminiAiFeature feature) => switch (feature) {
        GeminiAiFeature.ocr => 0,
        GeminiAiFeature.summary => 5500,
        GeminiAiFeature.flashcards => 4500,
        GeminiAiFeature.quiz => 4000,
        GeminiAiFeature.mindmap => 3500,
      };

  /// Hard cap on the full prompt sent to Gemini (characters).
  static int maxTotalPromptChars(GeminiAiFeature feature) => switch (feature) {
        GeminiAiFeature.ocr => 1200,
        GeminiAiFeature.summary => 7500,
        GeminiAiFeature.flashcards => 6500,
        GeminiAiFeature.quiz => 6500,
        GeminiAiFeature.mindmap => 6000,
      };

  /// Max tokens Gemini may generate in the response.
  static int maxOutputTokens(GeminiAiFeature feature) => switch (feature) {
        GeminiAiFeature.ocr => 2048,
        GeminiAiFeature.summary => 1536,
        GeminiAiFeature.flashcards => 2560,
        GeminiAiFeature.quiz => 4096,
        GeminiAiFeature.mindmap => 2560,
      };

  /// Upper bound when retrying after truncated JSON.
  static int maxOutputTokensRetryCap(GeminiAiFeature feature) => switch (feature) {
        GeminiAiFeature.ocr => 4096,
        GeminiAiFeature.summary => 3072,
        GeminiAiFeature.flashcards => 4096,
        GeminiAiFeature.quiz => 8192,
        GeminiAiFeature.mindmap => 4096,
      };

  static String truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    const suffix = '\n...[đã rút gọn]';
    final cut = maxLen - suffix.length;
    if (cut <= 0) return suffix.substring(0, maxLen.clamp(0, suffix.length));
    return '${text.substring(0, cut)}$suffix';
  }

  static String clampPrompt(GeminiAiFeature feature, String prompt) =>
      truncate(prompt, maxTotalPromptChars(feature));
}
