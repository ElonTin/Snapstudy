import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/flashcards/data/repositories/flashcard_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/models/study_session_model.dart';
import 'package:snapstudy/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import 'package:snapstudy/features/spaced_repetition/data/repositories/spaced_repetition_repository_impl.dart';
import '../../helpers/fake_gemini_api_client.dart';
import '../../helpers/hive_test_helper.dart';
import '../../helpers/session_fixtures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late SpacedRepetitionRepositoryImpl repository;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() async {
    await initHiveForRepositoryTests();
    final sessions = SessionRepositoryImpl(
      local: SessionLocalDataSource(),
      fileStorage: SessionFileStorage(),
    );
    final flashcards = FlashcardRepositoryImpl(
      sessions: sessions,
      gemini: FakeGeminiApiClient(const Success('{}')),
    );
    repository = SpacedRepetitionRepositoryImpl(
      sessions: sessions,
      flashcards: flashcards,
    );
  });

  test('getDueQueue includes cards from stored deck', () async {
    final session = testSessionWithDeck(id: 'ses_sr_1');
    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(session),
    );

    final result = await repository.getDueQueue();
    expect(result.isSuccess, true);
    expect(result.valueOrNull!.length, greaterThan(0));
    expect(result.valueOrNull!.first.sessionId, 'ses_sr_1');
  });

  test('getStats reports due counts', () async {
    final session = testSessionWithDeck(id: 'ses_sr_2');
    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(session),
    );

    final result = await repository.getStats();
    expect(result.isSuccess, true);
    expect(result.valueOrNull!.dueNow, greaterThan(0));
    expect(result.valueOrNull!.hasDue, isTrue);
  });
}
