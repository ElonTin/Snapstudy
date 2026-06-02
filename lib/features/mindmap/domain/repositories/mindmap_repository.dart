import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract interface class MindmapRepository {
  Future<Result<SessionMindmap>> generateAndSave({required StudySession session});

  Future<Result<SessionMindmap?>> getMindmap(String sessionId);
}
