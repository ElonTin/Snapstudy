import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/presentation/utils/session_display_labels.dart';

abstract final class SessionChatPromptBuilder {
  SessionChatPromptBuilder._();

  static String buildSystemPrompt(StudySession session) {
    final ocr = session.ocrResult?.fullText ?? '';
    final summary = session.aiSummary;
    final flashHints = session.flashcardDeck?.cards
            .take(4)
            .map((c) => '• ${c.front}')
            .join('\n') ??
        '';
    final quizHints = session.sessionQuiz?.questions
            .take(3)
            .map((q) => '• ${q.prompt}')
            .join('\n') ??
        '';

    return '''
Bạn là trợ lý học tập SNAPSTUDY — trả lời câu hỏi về buổi học hiện tại.

Môn: ${session.subjectName}
Buổi: ${SessionDisplayLabels.title(session)}
Chủ đề: ${summary?.detectedTopic ?? 'chưa phân tích'}
${summary != null ? 'Tóm tắt: ${summary.overview}' : ''}
${summary != null && summary.keyPoints.isNotEmpty ? 'Ý chính: ${summary.keyPoints.join('; ')}' : ''}

Nội dung OCR (rút gọn):
${GeminiTokenLimits.truncate(ocr, GeminiTokenLimits.maxInputOcrChars(GeminiAiFeature.chat))}

${flashHints.isNotEmpty ? 'Flashcard mẫu:\n$flashHints' : ''}
${quizHints.isNotEmpty ? 'Quiz mẫu:\n$quizHints' : ''}

Quy tắc:
- Trả lời tiếng Việt, ngắn gọn, dễ hiểu
- Chỉ dựa trên nội dung buổi học trên; nếu thiếu thông tin hãy nói rõ
- Giải thích công thức bằng LaTeX \$...\$ khi cần
- Không bịa đặt nội dung không có trong buổi học
''';
  }
}
