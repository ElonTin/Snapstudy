import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/features/ai_summary/data/repositories/ai_summary_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/models/study_session_model.dart';
import 'package:snapstudy/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import '../../helpers/fake_gemini_api_client.dart';
import '../../helpers/hive_test_helper.dart';
import '../../helpers/session_fixtures.dart';
import '../../helpers/test_helpers.dart';
import 'package:snapstudy/core/utils/result.dart';

void main() {
  late AiSummaryRepositoryImpl repository;
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
    repository = AiSummaryRepositoryImpl(
      sessions: sessions,
      gemini: FakeGeminiApiClient(const Success(validSummaryJson)),
    );
  });

  test('generateAndSave fails without OCR', () async {
    final session = testSessionWithOcr().copyWith(ocrResult: null);
    final result = await repository.generateAndSave(session: session);
    expect(result.isFailure, true);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('generateAndSave persists mock summary', () async {
    final session = testSessionWithOcr(id: 'ses_ai_1');
    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(session),
    );

    final result = await repository.generateAndSave(session: session);
    expect(result.isSuccess, true);
    expect(result.valueOrNull?.isReady, true);

    final loaded = await repository.getSummary('ses_ai_1');
    expect(loaded.valueOrNull?.detectedTopic, isNotEmpty);
  });

  test('getSummary returns null for unknown session', () async {
    final result = await repository.getSummary('missing');
    expect(result.isSuccess, true);
    expect(result.valueOrNull, isNull);
  });
}
