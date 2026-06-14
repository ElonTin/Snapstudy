import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/ai/presentation/providers/llm_providers.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/weak_areas/data/repositories/weak_areas_repository_impl.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/session_weak_areas_insight.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_item.dart';
import 'package:snapstudy/features/weak_areas/domain/repositories/weak_areas_repository.dart';

final weakAreasRepositoryProvider = Provider<WeakAreasRepository>((ref) {
  return WeakAreasRepositoryImpl(llm: ref.watch(textLlmClientProvider));
});

final sessionWeakAreasProvider =
    FutureProvider.family<List<WeakAreaItem>, String>((ref, sessionId) async {
  final sessionResult =
      await ref.read(sessionRepositoryProvider).getSessionById(sessionId);
  final session = sessionResult.fold(onSuccess: (s) => s, onFailure: (_) => null);
  if (session == null) return [];
  return ref.read(weakAreasRepositoryProvider).analyzeSession(session);
});

final sessionWeakAreasInsightProvider =
    AsyncNotifierProvider.family<SessionWeakAreasInsightController,
        SessionWeakAreasInsight?, String>(
  SessionWeakAreasInsightController.new,
);

class SessionWeakAreasInsightController
    extends FamilyAsyncNotifier<SessionWeakAreasInsight?, String> {
  @override
  Future<SessionWeakAreasInsight?> build(String sessionId) async {
    return ref.read(weakAreasRepositoryProvider).getCachedInsight(sessionId);
  }

  Future<void> generate({bool forceRefresh = false}) async {
    state = const AsyncLoading();
    final sessionResult =
        await ref.read(sessionRepositoryProvider).getSessionById(arg);
    final session =
        sessionResult.fold(onSuccess: (s) => s, onFailure: (_) => null);
    if (session == null) {
      state = const AsyncData(null);
      return;
    }

    final result = await ref.read(weakAreasRepositoryProvider).generateAiInsight(
          session: session,
          forceRefresh: forceRefresh,
        );

    state = result.fold(
      onSuccess: AsyncData.new,
      onFailure: (f) => AsyncError(f, StackTrace.current),
    );
  }
}

final globalWeakAreasProvider = FutureProvider<List<WeakAreaItem>>((ref) async {
  final result = await ref.read(sessionRepositoryProvider).getAllSessions();
  final sessions = result.fold(
    onSuccess: (List<StudySession> l) => l,
    onFailure: (_) => <StudySession>[],
  );
  return ref.read(weakAreasRepositoryProvider).analyzeAll(sessions);
});

/// Tự động trigger AI phân tích khi:
/// - Đã có tín hiệu yếu (quiz sai / flashcard khó)
/// - Chưa có insight được cache
/// Dùng trong WeakAreasPage để không cần user bấm thủ công.
final autoTriggerWeakAreasProvider =
    FutureProvider.family<void, String>((ref, sessionId) async {
  final cached = await ref
      .read(weakAreasRepositoryProvider)
      .getCachedInsight(sessionId);
  if (cached != null) return; // Đã có cache → không gọi lại

  final signals = await ref.watch(sessionWeakAreasProvider(sessionId).future);
  if (signals.isEmpty) return; // Không có tín hiệu yếu → bỏ qua

  // Trigger generate (không await để tránh block)
  ref.read(sessionWeakAreasInsightProvider(sessionId).notifier).generate();
});

