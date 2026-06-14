import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_pipeline_provider.dart';
import 'package:snapstudy/features/ai/presentation/providers/llm_providers.dart';
import 'package:snapstudy/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';

final useMockQuizProvider = Provider<bool>((ref) => EnvConfig.useMockQuiz);

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepositoryImpl(
    sessions: ref.watch(sessionRepositoryProvider),
    llm: ref.watch(textLlmClientProvider),
  );
});

class QuizProcessingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<SessionQuiz?> generateForSession(String sessionId) async {
    state = const AsyncLoading();

    SessionQuiz? result;

    state = await AsyncValue.guard(() async {
      final sessionResult =
          await ref.read(sessionRepositoryProvider).getSessionById(sessionId);
      final session = sessionResult.fold(
        onSuccess: (s) => s,
        onFailure: (_) => null,
      );
      if (session == null) return;

      final quizResult = await ref
          .read(quizRepositoryProvider)
          .generateAndSave(session: session);

      result = quizResult.fold(
        onSuccess: (q) => q,
        onFailure: pipelineFailure,
      );
      refreshSessionAfterPipeline(ref, sessionId);
      ref.invalidate(sessionQuizProvider(sessionId));
    });

    refreshSessionAfterPipeline(ref, sessionId);
    return state.hasError ? null : result;
  }
}

final quizProcessingProvider =
    AsyncNotifierProvider<QuizProcessingController, void>(
  QuizProcessingController.new,
);

final sessionQuizProvider =
    FutureProvider.family<SessionQuiz?, String>((ref, sessionId) async {
  final result = await ref.read(quizRepositoryProvider).getQuiz(sessionId);
  return result.fold(onSuccess: (q) => q, onFailure: (_) => null);
});
