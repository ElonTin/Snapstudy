import 'package:hive/hive.dart';
import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';

/// One-time migration from legacy `sessions_list` to per-session keys.
abstract final class SessionStorageMigration {
  static const String _migratedFlag = 'sessions_per_key_migrated';

  static Future<void> runIfNeeded({
    required Box<dynamic> sessionsBox,
    required Box<dynamic> settingsBox,
  }) async {
    if (settingsBox.get(_migratedFlag) == true) return;

    final legacy = sessionsBox.get(StorageKeys.sessionsList);
    if (legacy is List && legacy.isNotEmpty) {
      final ids = <String>[];
      for (final entry in legacy) {
        final json = Map<String, dynamic>.from(entry as Map);
        final id = json['id'] as String;
        _applyTimerDefaultsForMigration(json);
        await sessionsBox.put(StorageKeys.sessionKey(id), json);
        ids.add(id);
      }
      await sessionsBox.put(StorageKeys.sessionsIndex, ids);
      await sessionsBox.delete(StorageKeys.sessionsList);
    }

    await settingsBox.put(_migratedFlag, true);
  }

  static void _applyTimerDefaultsForMigration(Map<String, dynamic> json) {
    if (json.containsKey('accumulatedElapsedMs')) return;

    final startedAt = DateTime.parse(json['startedAt'] as String);
    final status = json['status'] as String?;

    if (status == SessionStatus.active.name) {
      json['accumulatedElapsedMs'] = 0;
      json.remove('timerRunningSince');
    } else if (json['endedAt'] != null) {
      final endedAt = DateTime.parse(json['endedAt'] as String);
      json['accumulatedElapsedMs'] =
          endedAt.difference(startedAt).inMilliseconds;
      json.remove('timerRunningSince');
    } else {
      json['accumulatedElapsedMs'] = 0;
      json.remove('timerRunningSince');
    }
  }
}
