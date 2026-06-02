import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ocr/data/services/text_recognition_service.dart';
import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:snapstudy/features/ocr/domain/services/equation_detector.dart';
import 'package:snapstudy/features/ocr/domain/services/keyword_extractor.dart';
import 'package:snapstudy/features/ocr/domain/services/subject_suggester.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

class OcrRepositoryImpl implements OcrRepository {
  OcrRepositoryImpl({
    required TextRecognitionService recognition,
    required SessionRepository sessions,
    this.geminiDelayBetweenCaptures = false,
  })  : _recognition = recognition,
        _sessions = sessions;

  final TextRecognitionService _recognition;
  final SessionRepository _sessions;
  final bool geminiDelayBetweenCaptures;

  @override
  Future<Result<SessionOcrResult>> recognizeAndSaveSession({
    required StudySession session,
    required List<Subject> subjects,
  }) async {
    if (session.queue.isEmpty) {
      return const Error(ValidationFailure('Buổi học không có ảnh để OCR.'));
    }

    final captures = <CaptureOcrResult>[];
    for (var i = 0; i < session.queue.length; i++) {
      final item = session.queue[i];
      if (geminiDelayBetweenCaptures && i > 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      final result = await _recognition.recognizeCapture(
        captureId: item.id,
        imagePath: item.localPath,
      );
      captures.add(result);
    }

    final sessionResult = _aggregate(session, captures, subjects);
    final saved = await _sessions.applyOcrResult(
      sessionId: session.id,
      ocrResult: sessionResult,
    );

    return saved.fold(
      onSuccess: (_) => Success(sessionResult),
      onFailure: Error.new,
    );
  }

  @override
  Future<Result<SessionOcrResult?>> getOcrResult(String sessionId) async {
    final session = await _sessions.getSessionById(sessionId);
    return session.fold(
      onSuccess: (s) => Success(s?.ocrResult),
      onFailure: Error.new,
    );
  }

  SessionOcrResult _aggregate(
    StudySession session,
    List<CaptureOcrResult> captures,
    List<Subject> subjects,
  ) {
    final success = captures.where((c) => c.isSuccess).toList();
    final fullText = success.map((c) => c.text).where((t) => t.isNotEmpty).join('\n\n');
    final keywords = KeywordExtractor.extract(fullText);
    final suggestion = SubjectSuggester.suggest(
      keywords: keywords,
      subjects: subjects,
      currentSubjectId: session.subjectId,
    );

    final avgConf = success.isEmpty
        ? 0.0
        : success.map((c) => c.confidence).reduce((a, b) => a + b) / success.length;

    final hasEquations = captures.any((c) => c.hasEquations) ||
        EquationDetector.containsEquations(fullText);

    OcrStatus status;
    if (success.isEmpty) {
      status = OcrStatus.failed;
    } else if (success.length < captures.length) {
      status = OcrStatus.partial;
    } else {
      status = OcrStatus.completed;
    }

    return SessionOcrResult(
      sessionId: session.id,
      fullText: fullText,
      captures: captures,
      keywords: keywords,
      suggestedSubjectId: suggestion.subjectId,
      suggestedSubjectName: suggestion.subjectName,
      suggestedSubjectConfidence: suggestion.confidence,
      averageConfidence: avgConf,
      hasEquations: hasEquations,
      status: status,
      processedAt: DateTime.now(),
      errorMessage: status == OcrStatus.failed ? 'Không nhận dạng được văn bản' : null,
    );
  }
}
