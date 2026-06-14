import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai/data/services/llm_json_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/flashcards/data/services/flashcard_json_parser.dart';
import 'package:snapstudy/features/flashcards/data/services/flashcard_prompt_builder.dart';
import 'package:snapstudy/features/flashcards/data/services/mock_flashcard_generator.dart';
import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/flashcards/domain/repositories/flashcard_repository.dart';
import 'package:snapstudy/features/flashcards/domain/services/sm2_scheduler.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  FlashcardRepositoryImpl({
    required SessionRepository sessions,
    required LlmJsonClient llm,
  })  : _sessions = sessions,
        _llm = llm;

  final SessionRepository _sessions;
  final LlmJsonClient _llm;

  @override
  Future<Result<SessionFlashcardDeck>> generateAndSave({
    required StudySession session,
  }) async {
    final ocr = session.ocrResult;
    if (ocr == null || ocr.fullText.trim().isEmpty) {
      return const Error(
        ValidationFailure('Cần OCR trước khi tạo flashcard.'),
      );
    }

    final Result<SessionFlashcardDeck> generated;
    if (EnvConfig.useMockFlashcards) {
      generated = Success(
        MockFlashcardGenerator.generate(
          session: session,
          summary: session.aiSummary,
        ),
      );
    } else {
      final prompt = FlashcardPromptBuilder.buildDeckPrompt(
        session: session,
        ocr: ocr,
        summary: session.aiSummary,
      );
      final raw = await _llm.generateJson(
        prompt: prompt,
        feature: GeminiAiFeature.flashcards,
      );
      generated = await raw.flatMap((jsonText) async {
        return FlashcardJsonParser.parse(
          sessionId: session.id,
          rawJson: jsonText,
          modelName: EnvConfig.activeTextLlmModel,
        );
      });
    }

    return await generated.flatMap((deck) async {
      final saved = await _sessions.applyFlashcardDeck(
        sessionId: session.id,
        deck: deck,
      );
      return saved.fold(
        onSuccess: (_) => Success(deck),
        onFailure: Error.new,
      );
    });
  }

  @override
  Future<Result<SessionFlashcardDeck?>> getDeck(String sessionId) async {
    final session = await _sessions.getSessionById(sessionId);
    return session.fold(
      onSuccess: (s) => Success(s?.flashcardDeck),
      onFailure: Error.new,
    );
  }

  @override
  Future<Result<SessionFlashcardDeck>> recordReview({
    required String sessionId,
    required String cardId,
    required ReviewRating rating,
  }) async {
    final sessionResult = await _sessions.getSessionById(sessionId);
    final session = sessionResult.fold(
      onSuccess: (s) => s,
      onFailure: (_) => null,
    );
    final deck = session?.flashcardDeck;
    if (deck == null) {
      return const Error(ValidationFailure('Chưa có bộ flashcard.'));
    }

    final index = deck.cards.indexWhere((c) => c.id == cardId);
    if (index < 0) {
      return const Error(ValidationFailure('Không tìm thấy thẻ.'));
    }

    final updated = List<Flashcard>.from(deck.cards);
    updated[index] = Sm2Scheduler.applyReview(updated[index], rating);

    final newDeck = SessionFlashcardDeck(
      sessionId: deck.sessionId,
      title: deck.title,
      cards: updated,
      status: deck.status,
      generatedAt: deck.generatedAt,
      modelName: deck.modelName,
    );

    final saved = await _sessions.applyFlashcardDeck(
      sessionId: sessionId,
      deck: newDeck,
    );
    return saved.fold(
      onSuccess: (_) => Success(newDeck),
      onFailure: Error.new,
    );
  }
}
