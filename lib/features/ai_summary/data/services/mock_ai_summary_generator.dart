import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/summary_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

/// Offline summary when Gemini API key is missing (dev / tests).
abstract final class MockAiSummaryGenerator {
  static SessionAiSummary generate({
    required StudySession session,
    required SessionOcrResult ocr,
  }) {
    final preview = ocr.fullText.length > 200
        ? '${ocr.fullText.substring(0, 200)}...'
        : ocr.fullText;

    return SessionAiSummary(
      sessionId: session.id,
      detectedTopic: session.title,
      overview:
          'Tóm tắt mẫu từ OCR buổi ${session.subjectName}. '
          'Bật GEMINI_API_KEY để dùng Gemini thật.',
      keyPoints: [
        if (ocr.keywords.isNotEmpty) 'Từ khóa: ${ocr.keywords.take(5).join(', ')}',
        'Số ảnh đã OCR: ${ocr.successCount}',
        'Độ tin cậy OCR: ${(ocr.averageConfidence * 100).round()}%',
        if (ocr.hasEquations) 'Có nội dung công thức',
      ],
      bulletSummary: [
        'Chủ đề: ${session.title}',
        'Môn: ${session.subjectName}',
        if (preview.isNotEmpty) 'Trích OCR: $preview',
      ],
      topics: ocr.keywords.take(4).toList(),
      status: SummaryStatus.completed,
      generatedAt: DateTime.now(),
      modelName: 'mock-dev',
    );
  }
}
