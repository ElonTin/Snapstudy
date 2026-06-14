import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/features/ai_summary/presentation/providers/ai_summary_providers.dart';
import 'package:snapstudy/features/home/presentation/providers/dashboard_provider.dart';
import 'package:snapstudy/features/ocr/domain/services/keyword_extractor.dart';
import 'package:snapstudy/features/ocr/domain/services/subject_suggester.dart';
import 'package:snapstudy/features/ocr/presentation/providers/ocr_providers.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_pipeline_step.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';
import 'package:snapstudy/features/subjects/presentation/providers/subject_providers.dart';

/// Refreshes session detail + dashboard after a pipeline step completes.
void refreshSessionAfterPipeline(Ref ref, String sessionId) {
  ref.invalidate(sessionDetailProvider(sessionId));
  ref.invalidate(dashboardProvider);
}

/// Throws so [AsyncValue.guard] surfaces errors in UI listeners.
Never pipelineFailure(Failure failure) => throw Exception(failure.message);

/// Progress of the automatic OCR → Summary pipeline.
class SessionPipelineState {
  const SessionPipelineState({
    this.sessionId,
    this.currentStep,
    this.completedSteps = const [],
    this.isRunning = false,
    this.error,
  });

  final String? sessionId;
  final SessionPipelineStep? currentStep;
  final List<SessionPipelineStep> completedSteps;
  final bool isRunning;
  final String? error;

  double get progress {
    final total = autoPipelineSteps.length;
    final done = completedSteps.where((s) => s.isAutomatic).length;
    final partial = currentStep != null && currentStep!.isAutomatic ? 0.5 : 0.0;
    return ((done + partial) / total).clamp(0, 1);
  }

  SessionPipelineState copyWith({
    String? sessionId,
    SessionPipelineStep? currentStep,
    List<SessionPipelineStep>? completedSteps,
    bool? isRunning,
    String? error,
    bool clearError = false,
    bool clearCurrentStep = false,
  }) {
    return SessionPipelineState(
      sessionId: sessionId ?? this.sessionId,
      currentStep: clearCurrentStep ? null : (currentStep ?? this.currentStep),
      completedSteps: completedSteps ?? this.completedSteps,
      isRunning: isRunning ?? this.isRunning,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GalleryOcrPreview {
  const GalleryOcrPreview({
    required this.text,
    required this.keywords,
    required this.suggestion,
  });

  final String text;
  final List<String> keywords;
  final SubjectSuggestion suggestion;
}

/// Tự động: OCR → Tóm tắt AI. Flashcard/Quiz/Mindmap chỉ khi người dùng bấm.
class SessionPipelineController extends Notifier<SessionPipelineState> {
  @override
  SessionPipelineState build() => const SessionPipelineState();

  bool needsPipeline(StudySession session) {
    if (session.queue.isEmpty) return false;
    if (session.status == SessionStatus.active) return false;
    return session.ocrResult == null || session.aiSummary == null;
  }

  Future<void> runIfNeeded(String sessionId) async {
    if (state.isRunning && state.sessionId == sessionId) return;

    final sessionResult =
        await ref.read(sessionRepositoryProvider).getSessionById(sessionId);
    final session = sessionResult.fold(
      onSuccess: (s) => s,
      onFailure: (_) => null,
    );
    if (session == null || !needsPipeline(session)) return;

    await run(sessionId);
  }

  Future<void> run(String sessionId) async {
    if (state.isRunning) return;

    state = SessionPipelineState(
      sessionId: sessionId,
      isRunning: true,
      completedSteps: const [],
    );

    try {
      await _setProcessing(sessionId, true);

      final session = await _loadSession(sessionId);
      if (session == null) {
        state = state.copyWith(isRunning: false, error: 'Không tìm thấy buổi học');
        return;
      }

      if (session.ocrResult == null) {
        await _runStep(
          sessionId,
          SessionPipelineStep.ocr,
          () => ref.read(ocrProcessingProvider.notifier).processSession(sessionId),
        );
      } else {
        _markCompleted(SessionPipelineStep.ocr);
      }

      final afterOcr = await _loadSession(sessionId);
      final hasText = afterOcr?.ocrResult?.fullText.trim().isNotEmpty ?? false;
      if (!hasText) {
        state = state.copyWith(isRunning: false, clearCurrentStep: true);
        await _setProcessing(sessionId, false);
        ref.invalidate(sessionDetailProvider(sessionId));
        ref.invalidate(dashboardProvider);
        return;
      }

      if (afterOcr?.aiSummary == null) {
        await _runStep(
          sessionId,
          SessionPipelineStep.summary,
          () => ref
              .read(aiSummaryProcessingProvider.notifier)
              .generateForSession(sessionId),
        );
      } else {
        _markCompleted(SessionPipelineStep.summary);
      }

      state = state.copyWith(isRunning: false, clearCurrentStep: true);
      await _setProcessing(sessionId, false);
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        clearCurrentStep: true,
        error: e.toString(),
      );
      await _setProcessing(sessionId, false);
    } finally {
      ref.invalidate(sessionDetailProvider(sessionId));
      ref.invalidate(dashboardProvider);
    }
  }

  Future<void> _runStep(
    String sessionId,
    SessionPipelineStep step,
    Future<dynamic> Function() action,
  ) async {
    state = state.copyWith(currentStep: step, clearError: true);
    await action();
    _markCompleted(step);
  }

  void _markCompleted(SessionPipelineStep step) {
    final steps = [...state.completedSteps];
    if (!steps.contains(step)) steps.add(step);
    state = state.copyWith(completedSteps: steps, clearCurrentStep: true);
    if (state.sessionId != null) {
      ref.invalidate(sessionDetailProvider(state.sessionId!));
    }
  }

  Future<StudySession?> _loadSession(String sessionId) async {
    final result =
        await ref.read(sessionRepositoryProvider).getSessionById(sessionId);
    return result.fold(onSuccess: (s) => s, onFailure: (_) => null);
  }

  Future<void> _setProcessing(String sessionId, bool processing) async {
    await ref.read(sessionRepositoryProvider).setSessionProcessing(
          sessionId: sessionId,
          processing: processing,
        );
  }

  void reset() {
    state = const SessionPipelineState();
  }
}

final sessionPipelineProvider =
    NotifierProvider<SessionPipelineController, SessionPipelineState>(
  SessionPipelineController.new,
);

final galleryPreviewOcrProvider =
    FutureProvider.family<GalleryOcrPreview, String>((ref, imagePath) async {
  final recognition = ref.watch(textRecognitionServiceProvider);
  final result = await recognition.recognizeCapture(
    captureId: 'preview',
    imagePath: imagePath,
  );

  final subjectsResult =
      await ref.read(subjectRepositoryProvider).getSubjects();
  final subjects = subjectsResult.fold(
    onSuccess: (List<Subject> list) => list,
    onFailure: (_) => <Subject>[],
  );

  final corpus = subjects.map((s) => s.name).toList();
  final tfIdfScores = KeywordExtractor.scoreTerms(result.text, corpusDocuments: corpus);
  final keywords = KeywordExtractor.extractTfIdf(
    result.text,
    corpusDocuments: corpus,
  );

  final suggestion = SubjectSuggester.suggest(
    keywords: keywords,
    subjects: subjects,
    tfIdfScores: tfIdfScores,
  );

  return GalleryOcrPreview(
    text: result.text,
    keywords: keywords,
    suggestion: suggestion,
  );
});
