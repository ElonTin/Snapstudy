import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/errors/app_exception.dart';
import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/features/sessions/data/models/study_session_model.dart';

/// Hive persistence — one key per session (no full-list rewrite).
class SessionLocalDataSource {
  Future<List<String>> _readIndex() async {
    final raw = HiveService.sessionsBox.get(StorageKeys.sessionsIndex);
    if (raw is! List) return [];
    return raw.cast<String>();
  }

  Future<void> _writeIndex(List<String> ids) async {
    await HiveService.sessionsBox.put(StorageKeys.sessionsIndex, ids);
  }

  Future<List<StudySessionModel>> readAll() async {
    try {
      final ids = await _readIndex();
      final sessions = <StudySessionModel>[];
      for (final id in ids) {
        final model = await readById(id);
        if (model != null) sessions.add(model);
      }
      return sessions;
    } catch (e) {
      throw CacheException('Không đọc được buổi học: $e');
    }
  }

  Future<StudySessionModel?> readById(String id) async {
    try {
      final raw = HiveService.sessionsBox.get(StorageKeys.sessionKey(id));
      if (raw == null) return null;
      return StudySessionModel.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (e) {
      throw CacheException('Không đọc buổi học $id: $e');
    }
  }

  Future<void> upsert(StudySessionModel session) async {
    try {
      var ids = await _readIndex();
      if (!ids.contains(session.id)) {
        ids = [session.id, ...ids];
        await _writeIndex(ids);
      }
      await HiveService.sessionsBox.put(
        StorageKeys.sessionKey(session.id),
        session.toJson(),
      );
    } catch (e) {
      throw CacheException('Không lưu buổi học: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final ids = await _readIndex();
      if (ids.remove(id)) {
        await _writeIndex(ids);
      }
      await HiveService.sessionsBox.delete(StorageKeys.sessionKey(id));
    } catch (e) {
      throw CacheException('Không xóa buổi học: $e');
    }
  }

  String? readActiveSessionId() =>
      HiveService.settingsBox.get(StorageKeys.activeSessionId) as String?;

  Future<void> writeActiveSessionId(String? id) async {
    if (id == null) {
      await HiveService.settingsBox.delete(StorageKeys.activeSessionId);
    } else {
      await HiveService.settingsBox.put(StorageKeys.activeSessionId, id);
    }
  }
}
