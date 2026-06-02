import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract final class QuizPromptBuilder {
  static String buildQuizPrompt({
    required StudySession session,
    required SessionOcrResult ocr,
    SessionAiSummary? summary,
    SessionFlashcardDeck? deck,
  }) {
    final summaryBlock = summary != null
        ? '''
Tóm tắt AI:
- Chủ đề: ${GeminiTokenLimits.truncate(summary.detectedTopic, 120)}
- Overview: ${GeminiTokenLimits.truncate(summary.overview, 350)}
- Key points: ${GeminiTokenLimits.truncate(summary.keyPoints.join('; '), 450)}
'''
        : '';

    final deckBlock = deck != null && deck.cards.isNotEmpty
        ? '''
Flashcard (${deck.cards.length} thẻ):
${deck.cards.take(6).map((c) => '- ${GeminiTokenLimits.truncate(c.front, 80)} → ${GeminiTokenLimits.truncate(c.back, 100)}').join('\n')}
'''
        : '';

    return '''
Bạn là trợ lý SNAPSTUDY. Tạo bài trắc nghiệm (MCQ) ôn tập từ buổi học.

Môn: ${session.subjectName}
Buổi: ${session.title}
$summaryBlock$deckBlock
Văn bản OCR (rút gọn):
---
${GeminiTokenLimits.truncate(ocr.fullText, GeminiTokenLimits.maxInputOcrChars(GeminiAiFeature.quiz))}
---

Trả về ĐÚNG MỘT JSON (không markdown):
{
  "title": "string — tên đề quiz",
  "defaultDifficulty": "easy | medium | hard",
  "questions": [
    {
      "prompt": "string — câu hỏi rõ ràng",
      "choices": ["đáp án A", "đáp án B", "đáp án C", "đáp án D"],
      "correctIndex": 0,
      "explanation": "string — giải thích ngắn tại sao đúng",
      "difficulty": "easy | medium | hard"
    }
  ]
}

Yêu cầu:
- 5 đến 6 câu, tiếng Việt
- Mỗi câu ĐÚNG 4 lựa chọn ngắn (≤ 40 ký tự), correctIndex 0–3
- explanation ≤ 80 ký tự
- JSON phải đóng đủ ngoặc, không cắt giữa chuỗi
''';
  }
}
