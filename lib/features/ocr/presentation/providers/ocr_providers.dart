import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/ai/presentation/providers/llm_providers.dart';
import 'package:snapstudy/features/ai_summary/presentation/providers/gemini_providers.dart';
import 'package:snapstudy/features/camera/presentation/providers/camera_providers.dart';
import 'package:snapstudy/features/ocr/data/repositories/ocr_repository_impl.dart';
import 'package:snapstudy/features/ocr/data/services/ocr_text_enhancer.dart';
import 'package:snapstudy/features/ocr/data/services/composite_text_recognition_service.dart';
import 'package:snapstudy/features/ocr/data/services/gemini_vision_ocr_service.dart';
import 'package:snapstudy/features/ocr/data/services/mlkit_text_recognition_service.dart';
import 'package:snapstudy/features/ocr/data/services/mock_text_recognition_service.dart';
import 'package:snapstudy/features/ocr/data/services/ocr_platform.dart';
import 'package:snapstudy/features/ocr/data/services/text_recognition_service.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_pipeline_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';
import 'package:snapstudy/features/subjects/presentation/providers/subject_providers.dart';

/// True when UI should warn that OCR output is sample data, not from the image.
final ocrUsesMockProvider = Provider<bool>((ref) => OcrPlatform.useMockRecognizer);

final ocrEngineLabelProvider = Provider<String>((ref) => OcrPlatform.engineLabel);

final textRecognitionServiceProvider = Provider<TextRecognitionService>((ref) {
  if (OcrPlatform.useMockRecognizer) {
    final mock = MockTextRecognitionService();
    ref.onDispose(mock.dispose);
    return mock;
  }

  TextRecognitionService? gemini;
  TextRecognitionService? mlkit;

  if (OcrPlatform.useGeminiVision) {
    gemini = GeminiVisionOcrService(gemini: ref.watch(geminiApiClientProvider));
  }

  if (OcrPlatform.supportsMlKit) {
    mlkit = MlKitTextRecognitionService();
  }

  if (gemini != null && mlkit != null) {
    final composite = CompositeTextRecognitionService(
      primary: gemini,
      fallback: mlkit,
    );
    ref.onDispose(composite.dispose);
    return composite;
  }

  final service = gemini ?? mlkit ?? MockTextRecognitionService();
  ref.onDispose(service.dispose);
  return service;
});

final ocrRepositoryProvider = Provider<OcrRepository>((ref) {
  return OcrRepositoryImpl(
    recognition: ref.watch(textRecognitionServiceProvider),
    sessions: ref.watch(sessionRepositoryProvider),
    captureProcessing: ref.watch(captureProcessingServiceProvider),
    textEnhancer: OcrTextEnhancer(llm: ref.watch(textLlmClientProvider)),
    geminiDelayBetweenCaptures: OcrPlatform.useGeminiVision,
  );
});

/// Runs OCR on demand (manual from session detail).
class OcrProcessingController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<SessionOcrResult?> processSession(String sessionId) async {
    state = const AsyncLoading();

    SessionOcrResult? result;

    state = await AsyncValue.guard(() async {
      final sessionResult =
          await ref.read(sessionRepositoryProvider).getSessionById(sessionId);
      final session = sessionResult.fold(
        onSuccess: (s) => s,
        onFailure: (_) => null,
      );
      if (session == null || session.queue.isEmpty) return;

      final subjectsResult =
          await ref.read(subjectRepositoryProvider).getSubjects();
      final subjects = subjectsResult.fold(
        onSuccess: (List<Subject> list) => list,
        onFailure: (_) => <Subject>[],
      );

      final ocrResult = await ref
          .read(ocrRepositoryProvider)
          .recognizeAndSaveSession(session: session, subjects: subjects);

      result = ocrResult.fold(
        onSuccess: (r) => r,
        onFailure: pipelineFailure,
      );
      refreshSessionAfterPipeline(ref, sessionId);
    });

    refreshSessionAfterPipeline(ref, sessionId);

    return state.hasError ? null : result;
  }
}

final ocrProcessingProvider =
    AsyncNotifierProvider<OcrProcessingController, void>(
  OcrProcessingController.new,
);

final sessionOcrProvider =
    FutureProvider.family<SessionOcrResult?, String>((ref, sessionId) async {
  final result = await ref.read(ocrRepositoryProvider).getOcrResult(sessionId);
  return result.fold(onSuccess: (r) => r, onFailure: (_) => null);
});
