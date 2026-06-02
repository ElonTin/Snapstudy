import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/notifications/presentation/providers/notification_providers.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:snapstudy/features/home/presentation/providers/dashboard_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/spaced_repetition/data/repositories/spaced_repetition_repository_impl.dart';
import 'package:snapstudy/features/spaced_repetition/domain/entities/review_queue_item.dart';
import 'package:snapstudy/features/spaced_repetition/domain/entities/spaced_repetition_stats.dart';
import 'package:snapstudy/features/spaced_repetition/domain/repositories/spaced_repetition_repository.dart';

final spacedRepetitionRepositoryProvider =
    Provider<SpacedRepetitionRepository>((ref) {
  return SpacedRepetitionRepositoryImpl(
    sessions: ref.watch(sessionRepositoryProvider),
    flashcards: ref.watch(flashcardRepositoryProvider),
  );
});

final spacedRepetitionStatsProvider =
    FutureProvider<SpacedRepetitionStats>((ref) async {
  final result = await ref.read(spacedRepetitionRepositoryProvider).getStats();
  return result.fold(
    onSuccess: (s) => s,
    onFailure: (f) => throw f,
  );
});

final reviewQueueProvider = FutureProvider.family<List<ReviewQueueItem>, String?>(
  (ref, sessionId) async {
    final result = await ref
        .read(spacedRepetitionRepositoryProvider)
        .getDueQueue(sessionId: sessionId);
    return result.fold(
      onSuccess: (q) => q,
      onFailure: (f) => throw f,
    );
  },
);

class ReviewSessionController extends Notifier<ReviewSessionState> {
  @override
  ReviewSessionState build() => const ReviewSessionState();

  void loadQueue(List<ReviewQueueItem> items) {
    state = ReviewSessionState(
      queue: items,
      index: 0,
      showBack: false,
      completed: items.isEmpty,
    );
  }

  void flip() {
    state = state.copyWith(showBack: !state.showBack);
  }

  Future<bool> rate(ReviewRating rating) async {
    if (state.completed || state.queue.isEmpty) return false;

    final item = state.queue[state.index];
    final result = await ref.read(spacedRepetitionRepositoryProvider).recordReview(
          sessionId: item.sessionId,
          cardId: item.card.id,
          rating: rating,
        );

    if (result.isFailure) return false;

    ref.invalidate(dashboardProvider);
    ref.invalidate(spacedRepetitionStatsProvider);
    ref.invalidate(reviewQueueProvider(null));
    ref.invalidate(reviewQueueProvider(item.sessionId));
    ref.invalidate(sessionFlashcardDeckProvider(item.sessionId));
    unawaited(syncAppNotifications(ref));

    final remaining = List<ReviewQueueItem>.from(state.queue)
      ..removeAt(state.index);
    if (remaining.isEmpty) {
      state = const ReviewSessionState(completed: true);
    } else {
      final nextIndex =
          state.index >= remaining.length ? 0 : state.index;
      state = ReviewSessionState(
        queue: remaining,
        index: nextIndex,
        showBack: false,
      );
    }
    return true;
  }
}

class ReviewSessionState {
  const ReviewSessionState({
    this.queue = const [],
    this.index = 0,
    this.showBack = false,
    this.completed = false,
  });

  final List<ReviewQueueItem> queue;
  final int index;
  final bool showBack;
  final bool completed;

  ReviewQueueItem? get current =>
      index < queue.length ? queue[index] : null;

  ReviewSessionState copyWith({
    List<ReviewQueueItem>? queue,
    int? index,
    bool? showBack,
    bool? completed,
  }) {
    return ReviewSessionState(
      queue: queue ?? this.queue,
      index: index ?? this.index,
      showBack: showBack ?? this.showBack,
      completed: completed ?? this.completed,
    );
  }
}

final reviewSessionControllerProvider =
    NotifierProvider<ReviewSessionController, ReviewSessionState>(
  ReviewSessionController.new,
);
