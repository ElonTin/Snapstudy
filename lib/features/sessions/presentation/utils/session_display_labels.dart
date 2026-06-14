import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

/// Nhãn hiển thị buổi học — ưu tiên chủ đề AI / dạng bài cụ thể.
abstract final class SessionDisplayLabels {
  SessionDisplayLabels._();

  static String title(StudySession session) {
    final aiTopic = session.aiSummary?.detectedTopic.trim();
    if (aiTopic != null && aiTopic.isNotEmpty) return aiTopic;

    final note = session.notes?.trim();
    if (note != null && note.isNotEmpty && note.length <= 80) return note;

    if (session.title.trim().isNotEmpty) return session.title.trim();

    return session.subjectName;
  }

  static String subtitle(StudySession session) {
    final parts = <String>[session.subjectName];

    final topic = session.aiSummary?.topics.isNotEmpty == true
        ? session.aiSummary!.topics.first
        : session.aiSummary?.detectedTopic;
    if (topic != null &&
        topic.isNotEmpty &&
        topic != title(session) &&
        !parts.contains(topic)) {
      parts.add(topic);
    }

    final keywords = session.ocrResult?.keywords.take(2).join(', ');
    if (keywords != null && keywords.isNotEmpty) {
      parts.add(keywords);
    }

    return parts.join(' · ');
  }

  static String metaLine(StudySession session, String relativeTime) =>
      '${session.photoCount} ảnh · $relativeTime';
}
