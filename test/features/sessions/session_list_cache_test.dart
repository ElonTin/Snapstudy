import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/cache/performance_caches.dart';
import 'package:snapstudy/core/cache/session_list_cache.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/models/study_session_model.dart';
import 'package:snapstudy/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import '../../helpers/hive_test_helper.dart';
import '../../helpers/session_fixtures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late SessionRepositoryImpl repository;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await initHiveForRepositoryTests();
    repository = SessionRepositoryImpl(
      local: SessionLocalDataSource(),
      fileStorage: SessionFileStorage(),
    );
  });

  test('getAllSessions populates cache until invalidated', () async {
    final session = testSessionWithOcr(id: 'ses_cache_1');
    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(session),
    );

    final first = await repository.getAllSessions();
    expect(first.isSuccess, true);

    final cached = SessionListCache.get();
    expect(cached, isNotNull);
    expect(cached!.length, 1);

    final second = await repository.getAllSessions();
    expect(identical(first.valueOrNull, second.valueOrNull), isTrue);
  });

  test('upsert invalidates session list cache', () async {
    await repository.getAllSessions();
    expect(SessionListCache.get(), isNotNull);

    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(testSessionWithOcr(id: 'ses_cache_2')),
    );
    PerformanceCaches.invalidateAll();

    expect(SessionListCache.get(), isNull);
  });
}
