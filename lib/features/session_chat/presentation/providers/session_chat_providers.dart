import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/ai/data/services/llm_chat_client.dart';
import 'package:snapstudy/features/ai/data/services/session_llm_chat_client.dart';
import 'package:snapstudy/features/ai/presentation/providers/llm_providers.dart';
import 'package:snapstudy/features/ai_summary/presentation/providers/gemini_providers.dart';
import 'package:snapstudy/features/session_chat/data/repositories/session_chat_repository_impl.dart';
import 'package:snapstudy/features/session_chat/domain/entities/chat_message_role.dart';
import 'package:snapstudy/features/session_chat/domain/entities/session_chat_message.dart';
import 'package:snapstudy/features/session_chat/domain/repositories/session_chat_repository.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';

final llmChatClientProvider = Provider<LlmChatClient>((ref) {
  return SessionLlmChatClient(
    groqDio: ref.watch(groqDioProvider),
    gemini: ref.watch(geminiApiClientProvider),
  );
});

final sessionChatRepositoryProvider = Provider<SessionChatRepository>((ref) {
  return SessionChatRepositoryImpl(chatClient: ref.watch(llmChatClientProvider));
});

final sessionChatMessagesProvider =
    FutureProvider.family<List<SessionChatMessage>, String>((ref, sessionId) {
  return ref.read(sessionChatRepositoryProvider).getMessages(sessionId);
});

final sessionChatProvider =
    AsyncNotifierProvider.family<SessionChatController, List<SessionChatMessage>, String>(
  SessionChatController.new,
);

class SessionChatController
    extends FamilyAsyncNotifier<List<SessionChatMessage>, String> {
  @override
  Future<List<SessionChatMessage>> build(String sessionId) async {
    return ref.read(sessionChatRepositoryProvider).getMessages(sessionId);
  }

  Future<void> send(String text) async {
    final sessionResult =
        await ref.read(sessionRepositoryProvider).getSessionById(arg);
    final session =
        sessionResult.fold(onSuccess: (s) => s, onFailure: (_) => null);
    if (session == null) return;

    final current = state.valueOrNull ?? [];
    final pendingUser = SessionChatMessage(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatMessageRole.user,
      content: text.trim(),
      createdAt: DateTime.now(),
    );
    state = AsyncData([...current, pendingUser]);

    final result = await ref.read(sessionChatRepositoryProvider).sendMessage(
          session: session,
          text: text,
        );

    if (result.isSuccess) {
      state = AsyncData(
        await ref.read(sessionChatRepositoryProvider).getMessages(arg),
      );
    } else {
      state = AsyncError(result.failureOrNull!, StackTrace.current);
    }
  }

  Future<void> clear() async {
    await ref.read(sessionChatRepositoryProvider).clearHistory(arg);
    state = const AsyncData([]);
  }
}
