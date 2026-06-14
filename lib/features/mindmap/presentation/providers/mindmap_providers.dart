import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/features/ai/presentation/providers/llm_providers.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_pipeline_provider.dart';
import 'package:snapstudy/features/mindmap/data/repositories/mindmap_repository_impl.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/mindmap/domain/repositories/mindmap_repository.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';

final useMockMindmapProvider = Provider<bool>((ref) => EnvConfig.useMockMindmap);

final mindmapRepositoryProvider = Provider<MindmapRepository>((ref) {
  return MindmapRepositoryImpl(
    sessions: ref.watch(sessionRepositoryProvider),
    llm: ref.watch(textLlmClientProvider),
  );
});

class MindmapProcessingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<SessionMindmap?> generateForSession(String sessionId) async {
    state = const AsyncLoading();

    SessionMindmap? result;

    state = await AsyncValue.guard(() async {
      final sessionResult =
          await ref.read(sessionRepositoryProvider).getSessionById(sessionId);
      final session = sessionResult.fold(
        onSuccess: (s) => s,
        onFailure: (_) => null,
      );
      if (session == null) return;

      final mapResult = await ref
          .read(mindmapRepositoryProvider)
          .generateAndSave(session: session);

      result = mapResult.fold(
        onSuccess: (m) => m,
        onFailure: pipelineFailure,
      );
      refreshSessionAfterPipeline(ref, sessionId);
      ref.invalidate(sessionMindmapProvider(sessionId));
    });

    refreshSessionAfterPipeline(ref, sessionId);
    return state.hasError ? null : result;
  }
}

final mindmapProcessingProvider =
    AsyncNotifierProvider<MindmapProcessingController, void>(
  MindmapProcessingController.new,
);

final sessionMindmapProvider =
    FutureProvider.family<SessionMindmap?, String>((ref, sessionId) async {
  final result =
      await ref.read(mindmapRepositoryProvider).getMindmap(sessionId);
  return result.fold(onSuccess: (m) => m, onFailure: (_) => null);
});
