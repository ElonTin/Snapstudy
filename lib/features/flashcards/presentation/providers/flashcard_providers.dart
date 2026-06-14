import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/features/ai/presentation/providers/llm_providers.dart';
import 'package:snapstudy/features/flashcards/data/repositories/flashcard_repository_impl.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/flashcards/domain/repositories/flashcard_repository.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_pipeline_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';

final useMockFlashcardsProvider =
    Provider<bool>((ref) => EnvConfig.useMockFlashcards);

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  return FlashcardRepositoryImpl(
    sessions: ref.watch(sessionRepositoryProvider),
    llm: ref.watch(textLlmClientProvider),
  );
});

class FlashcardProcessingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<SessionFlashcardDeck?> generateForSession(String sessionId) async {
    state = const AsyncLoading();

    SessionFlashcardDeck? result;

    state = await AsyncValue.guard(() async {
      final sessionResult =
          await ref.read(sessionRepositoryProvider).getSessionById(sessionId);
      final session = sessionResult.fold(
        onSuccess: (s) => s,
        onFailure: (_) => null,
      );
      if (session == null) return;

      final deckResult = await ref
          .read(flashcardRepositoryProvider)
          .generateAndSave(session: session);

      result = deckResult.fold(
        onSuccess: (d) => d,
        onFailure: pipelineFailure,
      );
      refreshSessionAfterPipeline(ref, sessionId);
      ref.invalidate(sessionFlashcardDeckProvider(sessionId));
    });

    refreshSessionAfterPipeline(ref, sessionId);
    return state.hasError ? null : result;
  }
}

final flashcardProcessingProvider =
    AsyncNotifierProvider<FlashcardProcessingController, void>(
  FlashcardProcessingController.new,
);

final sessionFlashcardDeckProvider =
    FutureProvider.family<SessionFlashcardDeck?, String>((ref, sessionId) async {
  final result = await ref.read(flashcardRepositoryProvider).getDeck(sessionId);
  return result.fold(onSuccess: (d) => d, onFailure: (_) => null);
});
