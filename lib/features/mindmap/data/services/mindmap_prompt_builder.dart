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
Tóm tắt AI:
- Chủ đề: ${GeminiTokenLimits.truncate(summary.detectedTopic, 120)}
- Key points: ${GeminiTokenLimits.truncate(summary.keyPoints.join('; '), 450)}
'''
        : '';

    final deckBlock = deck != null && deck.cards.isNotEmpty
        ? 'Flashcard: ${deck.cards.take(5).map((c) => GeminiTokenLimits.truncate(c.front, 60)).join('; ')}\n'
        : '';

    final quizBlock = quiz != null && quiz.questions.isNotEmpty
        ? 'Quiz: ${quiz.questions.take(3).map((q) => GeminiTokenLimits.truncate(q.prompt, 80)).join('; ')}\n'
        : '';

    return '''
Bạn là trợ lý SNAPSTUDY. Tạo sơ đồ tư duy (mindmap) dạng cây từ buổi học.

Môn: ${session.subjectName}
Buổi: ${session.title}
$summaryBlock$deckBlock$quizBlock
OCR (rút gọn):
---
${GeminiTokenLimits.truncate(ocr.fullText, GeminiTokenLimits.maxInputOcrChars(GeminiAiFeature.mindmap))}
---

Trả về ĐÚNG MỘT JSON (không markdown):
{
  "title": "string",
  "rootId": "node_root",
  "clusters": [
    { "id": "cluster_1", "label": "nhóm chủ đề", "color": "#5C6BC0" }
  ],
  "nodes": [
    {
      "id": "node_root",
      "label": "Chủ đề trung tâm",
      "parentId": null,
      "clusterId": "cluster_1",
      "summary": "mô tả ngắn"
    },
    {
      "id": "node_2",
      "label": "Nhánh con",
      "parentId": "node_root",
      "clusterId": "cluster_1",
      "summary": ""
    }
  ]
}

Yêu cầu:
- 8–15 node, tiếng Việt, cây phân cấp từ root (parentId null chỉ cho root)
- label ngắn (≤ 35 ký tự), summary tùy chọn ≤ 60 ký tự
- JSON phải đóng đủ ngoặc, không cắt giữa chuỗi
''';
  }
}
