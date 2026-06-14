import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/mindmap/data/repositories/mindmap_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/models/study_session_model.dart';
import 'package:snapstudy/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import '../../helpers/fake_llm_json_client.dart';
import '../../helpers/hive_test_helper.dart';
import '../../helpers/session_fixtures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MindmapRepositoryImpl repository;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await initHiveForRepositoryTests();
    final sessions = SessionRepositoryImpl(
      local: SessionLocalDataSource(),
      fileStorage: SessionFileStorage(),
    );
    repository = MindmapRepositoryImpl(
      sessions: sessions,
      llm: FakeLlmJsonClient(const Success('{}')),
    );
  });

  test('generateAndSave produces mock mindmap graph', () async {
    final session = testSessionWithOcr(id: 'ses_map_1');
    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(session),
    );

    final result = await repository.generateAndSave(session: session);
    expect(result.isSuccess, true);
    expect(result.valueOrNull!.nodes.length, greaterThan(2));
    expect(result.valueOrNull!.isReady, true);
  });

  test('getMindmap reads persisted graph', () async {
    final session = testSessionWithOcr(id: 'ses_map_2');
    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(session),
    );
    await repository.generateAndSave(session: session);

    final loaded = await repository.getMindmap('ses_map_2');
    expect(loaded.isSuccess, true);
    expect(loaded.valueOrNull, isNotNull);
  });
}
