import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/cache/dashboard_cache.dart';
import 'package:snapstudy/core/cache/performance_caches.dart';
import 'package:snapstudy/features/home/data/datasources/dashboard_local_datasource.dart';
import 'package:snapstudy/features/home/data/repositories/dashboard_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/models/study_session_model.dart';
import 'package:snapstudy/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/flashcards/data/repositories/flashcard_repository_impl.dart';
import 'package:snapstudy/features/spaced_repetition/data/repositories/spaced_repetition_repository_impl.dart';
import 'package:snapstudy/features/subjects/data/datasources/subject_local_datasource.dart';
import 'package:snapstudy/features/subjects/data/repositories/subject_repository_impl.dart';
import '../../helpers/fake_llm_json_client.dart';
import '../../helpers/hive_test_helper.dart';
import '../../helpers/session_fixtures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late DashboardRepositoryImpl repository;
  late SessionRepositoryImpl sessions;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await initHiveForRepositoryTests();
    sessions = SessionRepositoryImpl(
      local: SessionLocalDataSource(),
      fileStorage: SessionFileStorage(),
    );
    final subjects = SubjectRepositoryImpl(SubjectLocalDataSource());
    final flashcards = FlashcardRepositoryImpl(
      sessions: sessions,
      llm: FakeLlmJsonClient(const Success('{}')),
    );
    final sr = SpacedRepetitionRepositoryImpl(
      sessions: sessions,
      flashcards: flashcards,
    );
    repository = DashboardRepositoryImpl(
      DashboardLocalDataSource(subjects, sessions, sr),
    );
  });

  test('fetchDashboard returns success with empty data', () async {
    final result = await repository.fetchDashboard();
    expect(result.isSuccess, true);
    expect(result.valueOrNull?.subjects, isNotEmpty);
  });

  test('fetchDashboard uses TTL cache on second call', () async {
    PerformanceCaches.invalidateAll();
    DashboardCache.invalidate();

    final first = await repository.fetchDashboard();
    expect(first.isSuccess, true);

    final cached = DashboardCache.get();
    expect(cached, isNotNull);

    final second = await repository.fetchDashboard();
    expect(second.isSuccess, true);
    expect(identical(second.valueOrNull, cached), isTrue);
  });

  test('force refresh bypasses dashboard cache', () async {
    await repository.fetchDashboard();
    final stale = DashboardCache.get();

    final fresh = await repository.fetchDashboard(force: true);
    expect(fresh.isSuccess, true);
    expect(identical(fresh.valueOrNull, stale), isFalse);
  });

  test('dashboard reflects stored session', () async {
    final subject = testSubject();
    await SubjectRepositoryImpl(SubjectLocalDataSource()).createSubject(
      name: subject.name,
      colorValue: subject.colorValue,
      iconCodePoint: subject.iconCodePoint,
    );

    final session = testSessionWithOcr(id: 'ses_dash_1');
    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(session),
    );
    PerformanceCaches.invalidateAll();

    final result = await repository.fetchDashboard(force: true);
    expect(result.isSuccess, true);
    expect(
      result.valueOrNull!.recentSessions.any((r) => r.id == 'ses_dash_1'),
      isTrue,
    );
  });
}
