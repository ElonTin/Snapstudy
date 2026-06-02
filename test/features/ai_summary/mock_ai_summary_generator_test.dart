import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ai_summary/data/services/mock_ai_summary_generator.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/summary_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

void main() {
  test('mock generator produces ready summary', () {
    final session = StudySession(
      id: 's1',
      subjectId: 'sub1',
      subjectName: 'Toán',
      subjectColorValue: 0xFF0000FF,
      title: 'Buổi đạo hàm',
      startedAt: DateTime(2025, 1, 1),
      status: SessionStatus.ready,
    );

    final ocr = SessionOcrResult(
      sessionId: 's1',
      fullText: 'f(x) = x^2',
      captures: const [],
      keywords: ['đạo hàm', 'hàm số'],
      hasEquations: true,
      averageConfidence: 0.9,
      status: OcrStatus.completed,
      processedAt: DateTime(2025, 1, 1),
    );

    final summary = MockAiSummaryGenerator.generate(
      session: session,
      ocr: ocr,
    );

    expect(summary.isReady, true);
    expect(summary.status, SummaryStatus.completed);
    expect(summary.modelName, 'mock-dev');
    expect(summary.keyPoints.any((p) => p.contains('đạo hàm')), true);
  });
}
