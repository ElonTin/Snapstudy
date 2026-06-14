import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/features/weak_areas/data/models/session_weak_areas_insight_model.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/session_weak_areas_insight.dart';

class WeakAreasLocalDataSource {
  static String _key(String sessionId) => 'weak_areas:$sessionId';

  Future<SessionWeakAreasInsight?> read(String sessionId) async {
    final raw = HiveService.cacheBox.get(_key(sessionId));
    if (raw is! Map) return null;
    return SessionWeakAreasInsightModel.fromJson(
      Map<String, dynamic>.from(raw),
    ).toEntity();
  }

  Future<void> save(String sessionId, SessionWeakAreasInsight insight) async {
    await HiveService.cacheBox.put(
      _key(sessionId),
      SessionWeakAreasInsightModel.fromEntity(insight).toJson(),
    );
  }

  Future<void> delete(String sessionId) async {
    await HiveService.cacheBox.delete(_key(sessionId));
  }
}
