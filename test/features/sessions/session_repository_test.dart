import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapstudy/core/cache/performance_caches.dart';
import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/storage/hive_boxes.dart';
import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart' as sessions;
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

void main() {
  late SessionRepositoryImpl repository;

  setUp(() async {
    PerformanceCaches.invalidateAll();
    final dir = Directory.systemTemp.createTempSync('snapstudy_sessions_test_');
    Hive.init(dir.path);
    HiveService.settingsBox = await Hive.openBox(HiveBoxes.settings);
    HiveService.cacheBox = await Hive.openBox(HiveBoxes.cache);
    HiveService.subjectsBox = await Hive.openBox(HiveBoxes.subjects);
    HiveService.sessionsBox = await Hive.openBox(HiveBoxes.sessions);
    await HiveService.sessionsBox.delete(StorageKeys.sessionsList);
    await HiveService.sessionsBox.delete(StorageKeys.sessionsIndex);
    await HiveService.settingsBox.delete(StorageKeys.activeSessionId);

    repository = SessionRepositoryImpl(
      local: SessionLocalDataSource(),
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

  test('startSession creates active session', () async {
    final result = await repository.startSession(
      subject: testSubject,
      title: 'Buổi test',
    );

    expect(result.isSuccess, true);
    expect(result.valueOrNull?.status, sessions.SessionStatus.active);

    final active = await repository.getActiveSession();
    expect(active.valueOrNull?.id, result.valueOrNull?.id);
  });

  test('endSession clears active session', () async {
    final start = await repository.startSession(
      subject: testSubject,
      title: 'End test',
    );
    final id = start.valueOrNull!.id;

    final end = await repository.endSession(id);
    expect(end.isSuccess, true);
    expect(end.valueOrNull?.status, sessions.SessionStatus.draft);

    final active = await repository.getActiveSession();
    expect(active.valueOrNull, isNull);
  });
}
