import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/feedback/data/services/feedback_email_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum FeedbackStatus { idle, sending, success, error }

class FeedbackState {
  const FeedbackState({
    this.status = FeedbackStatus.idle,
    this.errorMessage,
  });

  final FeedbackStatus status;
  final String? errorMessage;

  bool get isIdle => status == FeedbackStatus.idle;
  bool get isSending => status == FeedbackStatus.sending;
  bool get isSuccess => status == FeedbackStatus.success;
  bool get isError => status == FeedbackStatus.error;

  FeedbackState copyWith({
    FeedbackStatus? status,
    String? errorMessage,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class FeedbackNotifier extends StateNotifier<FeedbackState> {
  FeedbackNotifier() : super(const FeedbackState());

  final _service = FeedbackEmailService();

  Future<void> send({
    required String feedbackType,
    required String message,
    required List<File> images,
    required String platform,
  }) async {
    if (state.isSending) return;

    state = const FeedbackState(status: FeedbackStatus.sending);

    try {
      await _service.send(
        feedbackType: feedbackType,
        message: message,
        imageFiles: images,
        platform: platform,
      );
      state = const FeedbackState(status: FeedbackStatus.success);
    } catch (e) {
      state = FeedbackState(
        status: FeedbackStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const FeedbackState();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final feedbackProvider =
    StateNotifierProvider.autoDispose<FeedbackNotifier, FeedbackState>(
  (_) => FeedbackNotifier(),
);
