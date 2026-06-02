import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/models/study_session_model.dart';
import 'package:snapstudy/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import '../../helpers/fake_gemini_api_client.dart';
import '../../helpers/hive_test_helper.dart';
import '../../helpers/session_fixtures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late QuizRepositoryImpl repository;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await initHiveForRepositoryTests();
    final sessions = SessionRepositoryImpl(
      local: SessionLocalDataSource(),
      fileStorage: SessionFileStorage(),
    );
    repository = QuizRepositoryImpl(
      sessions: sessions,
      gemini: FakeGeminiApiClient(const Success('{}')),
    );
  });

  test('generateAndSave produces mock quiz', () async {
    final session = testSessionWithOcr(id: 'ses_quiz_1');
    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(session),
    );

    final result = await repository.generateAndSave(session: session);
    expect(result.isSuccess, true);
    expect(result.valueOrNull!.questions.length, greaterThanOrEqualTo(5));
  });

  test('generateAndSave fails without OCR text', () async {
    final session = testSessionWithOcr().copyWith(
      ocrResult: testOcrResult(fullText: '   '),
    );
    final result = await repository.generateAndSave(session: session);
    expect(result.isFailure, true);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });
}
