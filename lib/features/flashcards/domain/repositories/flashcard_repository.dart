import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract interface class FlashcardRepository {
  Future<Result<SessionFlashcardDeck>> generateAndSave({
    required StudySession session,
  });

  Future<Result<SessionFlashcardDeck?>> getDeck(String sessionId);

  Future<Result<SessionFlashcardDeck>> recordReview({
    required String sessionId,
    required String cardId,
    required ReviewRating rating,
  });
}
