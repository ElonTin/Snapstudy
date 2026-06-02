import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

/// Builds Gemini prompts with strict JSON output schema.
abstract final class GeminiPromptBuilder {
  static String buildSummaryPrompt({
    required StudySession session,
    required SessionOcrResult ocr,
  }) {
    final keywords = ocr.keywords.isEmpty
        ? 'không có'
        : ocr.keywords.join(', ');

    return '''
Bạn là trợ lý học tập SNAPSTUDY. Tóm tắt bài giảng từ văn bản OCR dưới đây.

Môn học: ${session.subjectName}
Tiêu đề buổi: ${session.title}
Từ khóa OCR: $keywords
${ocr.hasEquations ? 'Có công thức/toán trong nội dung.' : ''}

Văn bản OCR:
---
${GeminiTokenLimits.truncate(ocr.fullText, GeminiTokenLimits.maxInputOcrChars(GeminiAiFeature.summary))}
---

Trả về ĐÚNG MỘT JSON (không markdown, không giải thích) theo schema:
{
  "detectedTopic": "string — chủ đề chính 1 câu",
  "overview": "string — tóm tắt 2-3 câu ngắn",
  "keyPoints": ["string — 3-5 ý quan trọng"],
  "bulletSummary": ["string — 4-6 gạch đầu dòng ngắn"],
  "topics": ["string — 2-4 chủ đề phụ"]
}

Viết bằng tiếng Việt, súc tích, chính xác với nội dung OCR. JSON phải đóng đủ ngoặc.
''';
  }
}
