import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract interface class AiSummaryRepository {
  Future<Result<SessionAiSummary>> generateAndSave({
    required StudySession session,
  });

  Future<Result<SessionAiSummary?>> getSummary(String sessionId);
}
