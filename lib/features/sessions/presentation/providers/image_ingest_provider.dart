import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/features/ai/presentation/providers/llm_providers.dart';
import 'package:snapstudy/features/ocr/data/services/ai_subject_classifier.dart';
import 'package:snapstudy/features/ocr/presentation/providers/ocr_providers.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_pipeline_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';
import 'package:snapstudy/features/subjects/domain/services/subject_resolver.dart';
import 'package:snapstudy/features/subjects/presentation/providers/subject_providers.dart';

enum ImageIngestStep {
  preparing,
  classifyingSubject,
  savingImages,
  runningAi,
  done,
}

class ImageIngestState {
  const ImageIngestState({
    this.isRunning = false,
    this.step,
    this.message,
    this.sessionId,
    this.error,
  });

  final bool isRunning;
  final ImageIngestStep? step;
  final String? message;
  final String? sessionId;
  final String? error;

  ImageIngestState copyWith({
    bool? isRunning,
    ImageIngestStep? step,
    String? message,
    String? sessionId,
    String? error,
    bool clearError = false,
  }) {
    return ImageIngestState(
      isRunning: isRunning ?? this.isRunning,
      step: step ?? this.step,
      message: message ?? this.message,
      sessionId: sessionId ?? this.sessionId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Ảnh → lưu nhanh → phân môn heuristic → OCR + tóm tắt chạy nền.
class ImageIngestController extends Notifier<ImageIngestState> {
  @override
  ImageIngestState build() => const ImageIngestState();

  Future<String?> ingest(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return null;
    if (state.isRunning) return null;

    state = const ImageIngestState(
      isRunning: true,
      step: ImageIngestStep.preparing,
      message: 'Đang chuẩn bị...',
    );

    try {
      final active =
          await ref.read(sessionRepositoryProvider).getActiveSession();
      final activeSession = active.fold(
        onSuccess: (s) => s,
        onFailure: (_) => null,
      );
      if (activeSession != null) {
        await ref.read(activeSessionProvider.notifier).endSession();
      }

      state = state.copyWith(
        step: ImageIngestStep.classifyingSubject,
        message: 'Đang nhận diện môn học...',
      );

      final recognition = ref.read(textRecognitionServiceProvider);
      final preview = await recognition.recognizeCapture(
        captureId: 'classify',
        imagePath: imagePaths.first,
      );

      final classifier = AiSubjectClassifier();
      final classification = await classifier.classifyFast(preview.text);
      final classified = classification.fold(
        onSuccess: (c) => c,
        onFailure: (_) => null,
      );

      final subjectResult = await SubjectResolver.resolveOrCreate(
        repository: ref.read(subjectRepositoryProvider),
        subjectName: classified?.subjectName ?? 'Tổng hợp',
      );

      final subject = subjectResult.fold(
        onSuccess: (s) => s,
        onFailure: (f) {
          state = ImageIngestState(isRunning: false, error: f.message);
          return null;
        },
      );
      if (subject == null) return null;

      final title = classified?.topic?.isNotEmpty == true
          ? classified!.topic!
          : 'Bài học ${DateTime.now().day}/${DateTime.now().month}';

      state = state.copyWith(
        step: ImageIngestStep.savingImages,
        message: 'Đang lưu ${imagePaths.length} ảnh...',
      );

      final session = await ref.read(activeSessionProvider.notifier).startSession(
            subject: subject,
            title: title,
            notes: classified?.displayLabel,
          );
      if (session == null) {
        state = const ImageIngestState(
          isRunning: false,
          error: 'Không tạo được buổi học',
        );
        return null;
      }

      await ref.read(activeSessionProvider.notifier).addCaptures(
            imagePaths,
            processImages: true,
          );

      final ended =
          await ref.read(activeSessionProvider.notifier).endSession();
      if (ended == null) {
        state = const ImageIngestState(
          isRunning: false,
          error: 'Không lưu được buổi học',
        );
        return null;
      }

      state = ImageIngestState(
        isRunning: false,
        step: ImageIngestStep.done,
        sessionId: ended.id,
        message: 'Đã lưu — AI đang phân tích nền',
      );

      ref.invalidate(subjectsControllerProvider);

      unawaited(_runPipelineInBackground(ended.id));
      if (EnvConfig.isTextLlmConfigured && preview.text.trim().isNotEmpty) {
        unawaited(_refineSubjectWithLlm(ended.id, preview.text, subject));
      }

      return ended.id;
    } catch (e) {
      state = ImageIngestState(isRunning: false, error: e.toString());
      return null;
    }
  }

  Future<void> _runPipelineInBackground(String sessionId) async {
    try {
      await ref.read(sessionPipelineProvider.notifier).run(sessionId);
    } catch (_) {}
  }

  Future<void> _refineSubjectWithLlm(
    String sessionId,
    String ocrSample,
    Subject currentSubject,
  ) async {
    final classifier = AiSubjectClassifier(
      llm: ref.read(textLlmClientProvider),
    );
    final result = await classifier.classify(ocrSample);
    final refined = result.fold(onSuccess: (c) => c, onFailure: (_) => null);
    if (refined == null || refined.confidence < 0.65) return;
    if (refined.subjectName == currentSubject.name) return;

    final resolved = await SubjectResolver.resolveOrCreate(
      repository: ref.read(subjectRepositoryProvider),
      subjectName: refined.subjectName,
    );
    final subject = resolved.fold(onSuccess: (s) => s, onFailure: (_) => null);
    if (subject == null) return;

    await ref.read(sessionRepositoryProvider).updateSessionSubject(
          sessionId: sessionId,
          subject: subject,
        );
    ref.invalidate(sessionDetailProvider(sessionId));
    ref.invalidate(subjectsControllerProvider);
  }

  void reset() => state = const ImageIngestState();
}

final imageIngestProvider =
    NotifierProvider<ImageIngestController, ImageIngestState>(
  ImageIngestController.new,
);
