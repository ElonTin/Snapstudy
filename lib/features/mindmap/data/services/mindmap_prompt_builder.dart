import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract final class MindmapPromptBuilder {
  static String buildMindmapPrompt({
    required StudySession session,
    required SessionOcrResult ocr,
    SessionAiSummary? summary,
    SessionFlashcardDeck? deck,
    SessionQuiz? quiz,
  }) {
    final summaryBlock = summary != null
        ? '''
Chủ đề chính: ${GeminiTokenLimits.truncate(summary.detectedTopic, 100)}
Ý cốt lõi: ${GeminiTokenLimits.truncate(summary.keyPoints.take(4).join(' · '), 350)}
'''
        : '';

    final deckBlock = deck != null && deck.cards.isNotEmpty
        ? 'Flashcard: ${deck.cards.take(4).map((c) => GeminiTokenLimits.truncate(c.front, 40)).join(' · ')}\n'
        : '';

    final quizBlock = quiz != null && quiz.questions.isNotEmpty
        ? 'Quiz: ${quiz.questions.take(2).map((q) => GeminiTokenLimits.truncate(q.prompt, 60)).join(' · ')}\n'
        : '';

    return '''
Bạn là chuyên gia sư phạm SNAPSTUDY. Tạo mindmap SÚC TÍCH, DỄ NHÌN trên điện thoại.

Môn: ${session.subjectName}
Buổi: ${session.title}
$summaryBlock$deckBlock$quizBlock
OCR (rút gọn):
---
${GeminiTokenLimits.truncate(ocr.fullText, GeminiTokenLimits.maxInputOcrChars(GeminiAiFeature.mindmap))}
---

Trả về ĐÚNG MỘT JSON (không markdown):
{
  "title": "string — tên mindmap ngắn",
  "rootId": "node_root",
  "clusters": [
    { "id": "cluster_1", "label": "Khái niệm", "color": "#5C6BC0" },
    { "id": "cluster_2", "label": "Công thức", "color": "#26A69A" }
  ],
  "nodes": [
    { "id": "node_root", "label": "Chủ đề trung tâm", "parentId": null, "clusterId": "cluster_1", "summary": "" },
    { "id": "node_a", "label": "Nhánh A", "parentId": "node_root", "clusterId": "cluster_1", "summary": "1 câu ngắn" }
  ]
}

QUY TẮC BẮT BUỘC:
- TỐI ĐA 9 node (không hơn), tối thiểu 5 node
- Tối đa 3 tầng: root → 2–4 nhánh chính → 0–2 lá mỗi nhánh
- label: 2–5 từ, ≤ 24 ký tự, không câu dài
- summary: tùy chọn, ≤ 50 ký tự, chỉ cho nhánh quan trọng
- Gom ý liên quan, bỏ chi tiết rườm rà — ưu tiên khái niệm, công thức, dạng bài
- Tiếng Việt, JSON đóng đủ ngoặc
''';
  }
}
