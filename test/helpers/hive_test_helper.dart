import 'dart:io';

import 'package:hive/hive.dart';
import 'package:snapstudy/core/cache/performance_caches.dart';
import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/storage/hive_boxes.dart';
import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_storage_migration.dart';

/// Opens all Hive boxes used by repository integration tests.
Future<void> initHiveForRepositoryTests() async {
  PerformanceCaches.invalidateAll();

  final dir = Directory.systemTemp.createTempSync('snapstudy_hive_repo_');
  Hive.init(dir.path);

  HiveService.settingsBox = await Hive.openBox(HiveBoxes.settings);
  HiveService.cacheBox = await Hive.openBox(HiveBoxes.cache);
  HiveService.subjectsBox = await Hive.openBox(HiveBoxes.subjects);
  HiveService.sessionsBox = await Hive.openBox(HiveBoxes.sessions);

  await _clearSessionData();
  await HiveService.settingsBox.delete(StorageKeys.subjectsSeeded);
  await HiveService.settingsBox.put(StorageKeys.onboardingCompleted, true);

  await SessionStorageMigration.runIfNeeded(
    sessionsBox: HiveService.sessionsBox,
    settingsBox: HiveService.settingsBox,
  );
}

Future<void> _clearSessionData() async {
  await HiveService.sessionsBox.delete(StorageKeys.sessionsList);
  await HiveService.sessionsBox.delete(StorageKeys.sessionsIndex);
  await HiveService.settingsBox.delete(StorageKeys.activeSessionId);
}

/// Clears sessions between tests while keeping subject seed state.
Future<void> resetSessionHiveData() async {
  PerformanceCaches.invalidateAll();
  final keys = HiveService.sessionsBox.keys
      .whereType<String>()
      .where((k) => k.startsWith('session_'))
      .toList();
  for (final key in keys) {
    await HiveService.sessionsBox.delete(key);
  }
  await _clearSessionData();
}
