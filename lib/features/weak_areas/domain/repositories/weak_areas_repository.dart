import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/session_weak_areas_insight.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_item.dart';

abstract interface class WeakAreasRepository {
  List<WeakAreaItem> analyzeSession(StudySession session);

  List<WeakAreaItem> analyzeAll(List<StudySession> sessions);

  Future<Result<SessionWeakAreasInsight>> generateAiInsight({
    required StudySession session,
    bool forceRefresh = false,
  });

  Future<SessionWeakAreasInsight?> getCachedInsight(String sessionId);
}
