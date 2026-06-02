import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/features/flashcards/data/services/mock_flashcard_generator.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

Subject testSubject({
  String id = 'sub_test',
  String name = 'Toán',
}) =>
    Subject(
      id: id,
      name: name,
      colorValue: AppColors.primary.toARGB32(),
      iconCodePoint: 0xe24b,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

SessionOcrResult testOcrResult({
  String sessionId = 'ses_test',
  String fullText = 'Đạo hàm f(x) = x^2. Tích phân và ứng dụng.',
}) =>
    SessionOcrResult(
      sessionId: sessionId,
      fullText: fullText,
      captures: const [],
      keywords: const ['đạo hàm', 'tích phân'],
      hasEquations: true,
      averageConfidence: 0.92,
      status: OcrStatus.completed,
      processedAt: DateTime(2025, 1, 2),
    );

StudySession testSessionWithOcr({
  String id = 'ses_test',
  String subjectId = 'sub_test',
}) {
  final ocr = testOcrResult(sessionId: id);
  return StudySession(
    id: id,
    subjectId: subjectId,
    subjectName: 'Toán',
    subjectColorValue: AppColors.primary.toARGB32(),
    title: 'Buổi test OCR',
    startedAt: DateTime(2025, 1, 1),
    endedAt: DateTime(2025, 1, 1, 1),
    status: SessionStatus.ready,
    ocrResult: ocr,
    aiSummaryReady: false,
  );
}

StudySession testSessionWithDeck({
  String id = 'ses_deck',
  String subjectId = 'sub_test',
}) {
  final base = testSessionWithOcr(id: id, subjectId: subjectId);
  final deck = MockFlashcardGenerator.generate(session: base, summary: null);
  return base.copyWith(
    flashcardsReady: true,
    flashcardDeck: deck,
    aiSummaryReady: true,
  );
}

const validSummaryJson = '''
{
  "detectedTopic": "Đạo hàm",
  "overview": "Buổi học về đạo hàm cơ bản.",
  "keyPoints": ["Định nghĩa", "Quy tắc"],
  "bulletSummary": ["f'(x)", "Ứng dụng"],
  "topics": ["Toán", "Calculus"]
}
''';
