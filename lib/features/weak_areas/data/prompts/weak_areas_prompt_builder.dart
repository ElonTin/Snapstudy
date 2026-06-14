import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/presentation/utils/session_display_labels.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_item.dart';

abstract final class WeakAreasPromptBuilder {
  WeakAreasPromptBuilder._();

  static String build({
    required StudySession session,
    required List<WeakAreaItem> signals,
  }) {
    final summary = session.aiSummary;
    final signalLines = signals
        .take(8)
        .map((s) => '- [${s.source.name}] ${s.label}: ${s.reason}')
        .join('\n');

    return '''
Bạn là cố vấn học tập SNAPSTUDY. Phân tích điểm yếu của học sinh và đưa kế hoạch ôn tập ngắn gọn.

Môn: ${session.subjectName}
Buổi học: ${SessionDisplayLabels.title(session)}
Chủ đề AI: ${summary?.detectedTopic ?? 'chưa có'}
Điểm chính: ${summary?.keyPoints.take(4).join('; ') ?? 'chưa có'}

Tín hiệu yếu từ quiz / flashcard:
$signalLines

Trả về ĐÚNG MỘT JSON (không markdown):
{
  "aiAdvice": "string — 2-4 câu lời khuyên ôn tập cụ thể, tiếng Việt",
  "focusTopics": [
    {
      "label": "string — chủ đề/dạng bài cần ôn",
      "reason": "string — vì sao yếu",
      "action": "string — gợi ý hành động (ôn flashcard, làm lại quiz, đọc lại phần...)"
    }
  ]
}

focusTopics: 2-5 mục, ưu tiên tín hiệu mạnh nhất. JSON phải đóng đủ ngoặc.
''';
  }
}
