import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

abstract interface class OcrRepository {
  /// Runs OCR on all captures in a session and persists the result.
  Future<Result<SessionOcrResult>> recognizeAndSaveSession({
    required StudySession session,
    required List<Subject> subjects,
  });

  Future<Result<SessionOcrResult?>> getOcrResult(String sessionId);
}
