import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/flashcards/data/repositories/flashcard_repository_impl.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/models/study_session_model.dart';
import 'package:snapstudy/features/sessions/data/repositories/session_repository_impl.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import '../../helpers/fake_gemini_api_client.dart';
import '../../helpers/hive_test_helper.dart';
import '../../helpers/session_fixtures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late FlashcardRepositoryImpl repository;
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
    repository = FlashcardRepositoryImpl(
      sessions: sessions,
      gemini: FakeGeminiApiClient(const Success('{}')),
    );
  });

  test('generateAndSave creates deck from mock', () async {
    final session = testSessionWithOcr(id: 'ses_fc_1');
    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(session),
    );

    final result = await repository.generateAndSave(session: session);
    expect(result.isSuccess, true);
    expect(result.valueOrNull!.cards.length, greaterThanOrEqualTo(3));
  });

  test('recordReview updates card scheduling', () async {
    final session = testSessionWithDeck(id: 'ses_fc_rev');
    await SessionLocalDataSource().upsert(
      StudySessionModel.fromEntity(session),
    );
    final cardId = session.flashcardDeck!.cards.first.id;

    final result = await repository.recordReview(
      sessionId: 'ses_fc_rev',
      cardId: cardId,
      rating: ReviewRating.good,
    );

    expect(result.isSuccess, true);
    expect(result.valueOrNull!.cards.first.repetitions, greaterThan(0));
  });

  test('recordReview fails when deck missing', () async {
    final session = testSessionWithOcr(id: 'ses_fc_no_deck');
    final result = await repository.recordReview(
      sessionId: session.id,
      cardId: 'x',
      rating: ReviewRating.good,
    );
    expect(result.isFailure, true);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });
}
