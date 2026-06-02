import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract final class FlashcardPromptBuilder {
  static String buildDeckPrompt({
    required StudySession session,
    required SessionOcrResult ocr,
    SessionAiSummary? summary,
  }) {
    final summaryBlock = summary != null
        ? '''
Tóm tắt AI:
- Chủ đề: ${GeminiTokenLimits.truncate(summary.detectedTopic, 120)}
- Overview: ${GeminiTokenLimits.truncate(summary.overview, 400)}
- Key points: ${GeminiTokenLimits.truncate(summary.keyPoints.join('; '), 500)}
'''
        : '';

    return '''
Bạn là trợ lý SNAPSTUDY. Tạo bộ flashcard ôn tập từ buổi học dưới đây.

Môn: ${session.subjectName}
Buổi: ${session.title}
$summaryBlock
Văn bản OCR (rút gọn):
---
${GeminiTokenLimits.truncate(ocr.fullText, GeminiTokenLimits.maxInputOcrChars(GeminiAiFeature.flashcards))}
---

Trả về ĐÚNG MỘT JSON (không markdown):
{
  "title": "string — tên bộ thẻ",
  "cards": [
    {
      "front": "string — câu hỏi/Thuật ngữ (ngắn)",
      "back": "string — đáp án/giải thích súc tích",
      "hint": "string — gợi ý tùy chọn hoặc rỗng",
      "tags": ["string"]
    }
  ]
}

Yêu cầu:
- 6 đến 10 thẻ, tiếng Việt
- front/back ngắn gọn (mỗi mặt ≤ 120 ký tự)
- JSON phải đóng đủ ngoặc, không cắt giữa chuỗi
''';
  }
}
