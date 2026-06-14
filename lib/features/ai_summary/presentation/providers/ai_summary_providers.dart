import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/features/ai_summary/data/repositories/ai_summary_repository_impl.dart';
import 'package:snapstudy/features/ai/presentation/providers/llm_providers.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/ai_summary/domain/repositories/ai_summary_repository.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_pipeline_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';

final useMockAiSummaryProvider =
    Provider<bool>((ref) => EnvConfig.useMockAiSummary);

final aiSummaryRepositoryProvider = Provider<AiSummaryRepository>((ref) {
  return AiSummaryRepositoryImpl(
    sessions: ref.watch(sessionRepositoryProvider),
    llm: ref.watch(textLlmClientProvider),
  );
});

/// Generates AI summary after OCR (or manual retry).
class AiSummaryProcessingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<SessionAiSummary?> generateForSession(String sessionId) async {
    state = const AsyncLoading();

    SessionAiSummary? result;

    state = await AsyncValue.guard(() async {
      final sessionResult = await ref
          .read(sessionRepositoryProvider)
          .getSessionById(sessionId);
      final session = sessionResult.fold(
        onSuccess: (s) => s,
        onFailure: (_) => null,
      );
      if (session == null) return;

      final summaryResult = await ref
          .read(aiSummaryRepositoryProvider)
          .generateAndSave(session: session);

      result = summaryResult.fold(
        onSuccess: (s) => s,
        onFailure: pipelineFailure,
      );
      refreshSessionAfterPipeline(ref, sessionId);
    });

    refreshSessionAfterPipeline(ref, sessionId);
    return state.hasError ? null : result;
  }
}

final aiSummaryProcessingProvider =
    AsyncNotifierProvider<AiSummaryProcessingController, void>(
  AiSummaryProcessingController.new,
);

final sessionAiSummaryProvider =
    FutureProvider.family<SessionAiSummary?, String>((ref, sessionId) async {
  final result =
      await ref.read(aiSummaryRepositoryProvider).getSummary(sessionId);
  return result.fold(onSuccess: (s) => s, onFailure: (_) => null);
});
