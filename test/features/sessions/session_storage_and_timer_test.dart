import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapstudy/core/cache/performance_caches.dart';
import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/storage/hive_boxes.dart';
import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_storage_migration.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

void main() {
  late SessionRepositoryImpl repository;
  late SessionLocalDataSource local;

  setUp(() async {
    PerformanceCaches.invalidateAll();
    final dir = Directory.systemTemp.createTempSync('snapstudy_storage_test_');
    Hive.init(dir.path);
    HiveService.settingsBox = await Hive.openBox(HiveBoxes.settings);
    HiveService.cacheBox = await Hive.openBox(HiveBoxes.cache);
    HiveService.subjectsBox = await Hive.openBox(HiveBoxes.subjects);
    HiveService.sessionsBox = await Hive.openBox(HiveBoxes.sessions);
    await HiveService.sessionsBox.delete(StorageKeys.sessionsList);
    await HiveService.sessionsBox.delete(StorageKeys.sessionsIndex);
    await HiveService.settingsBox.delete(StorageKeys.activeSessionId);
    await SessionStorageMigration.runIfNeeded(
      sessionsBox: HiveService.sessionsBox,
      settingsBox: HiveService.settingsBox,
    );

    local = SessionLocalDataSource();
    repository = SessionRepositoryImpl(
      local: local,
      fileStorage: SessionFileStorage(),
    );
  });

  final testSubject = Subject(
    id: 'sub-test',
    name: 'Test',
    colorValue: 0xFF0000FF,
    iconCodePoint: 0xe24b,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  test('upsert stores session under per-id hive key', () async {
    final first = await repository.startSession(
      subject: testSubject,
      title: 'Only',
    );
    final id = first.valueOrNull!.id;

    expect(HiveService.sessionsBox.get(StorageKeys.sessionKey(id)), isNotNull);
    expect(HiveService.sessionsBox.get(StorageKeys.sessionsIndex), isNotNull);
  });

  test('pauseActiveSessionTimer stops background counting', () async {
    final start = await repository.startSession(
      subject: testSubject,
      title: 'Timer',
    );
    final id = start.valueOrNull!.id;

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final paused = await repository.pauseActiveSessionTimer();
    final elapsedWhenPaused = paused.valueOrNull!.elapsed;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    final reloaded = await repository.getSessionById(id);
    expect(reloaded.valueOrNull!.elapsed, elapsedWhenPaused);
    expect(reloaded.valueOrNull!.isTimerRunning, false);
  });

  test('resume continues from accumulated elapsed', () async {
    await repository.startSession(
      subject: testSubject,
      title: 'Resume',
    );
    await repository.pauseActiveSessionTimer();
    final before = (await repository.getActiveSession()).valueOrNull!.elapsed;

    await repository.resumeActiveSessionTimer();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await repository.pauseActiveSessionTimer();

    final after = (await repository.getActiveSession()).valueOrNull!.elapsed;
    expect(after > before, true);
  });

  test('endSession clears active id', () async {
    final start = await repository.startSession(
      subject: testSubject,
      title: 'End',
    );
    final id = start.valueOrNull!.id;

    final end = await repository.endSession(id);
    expect(end.isSuccess, true);
    expect(end.valueOrNull?.status, SessionStatus.draft);

    final active = await repository.getActiveSession();
    expect(active.valueOrNull, isNull);
  });
}
