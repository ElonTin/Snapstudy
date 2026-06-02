import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_prompt_builder.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

void main() {
  test('buildSummaryPrompt includes subject and OCR text', () {
    final session = StudySession(
      id: 's1',
      subjectId: 'sub1',
      subjectName: 'Lý',
      subjectColorValue: 0xFF00FF00,
      title: 'Chương 2',
      startedAt: DateTime(2025, 1, 1),
      status: SessionStatus.ready,
    );

    final ocr = SessionOcrResult(
      sessionId: 's1',
      fullText: 'Định luật Newton',
      captures: const [],
      keywords: ['lực', 'gia tốc'],
      hasEquations: false,
      averageConfidence: 0.85,
      status: OcrStatus.completed,
      processedAt: DateTime(2025, 1, 1),
    );

    final prompt = GeminiPromptBuilder.buildSummaryPrompt(
      session: session,
      ocr: ocr,
    );

    expect(prompt, contains('Lý'));
    expect(prompt, contains('Chương 2'));
    expect(prompt, contains('Định luật Newton'));
    expect(prompt, contains('detectedTopic'));
    expect(prompt, contains('lực'));
  });
}
