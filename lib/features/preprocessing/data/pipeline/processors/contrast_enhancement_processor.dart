import 'package:image/image.dart' as img;
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_state.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_result.dart';

/// Contrast + brightness normalization (CLAHE-like).
class ContrastEnhancementProcessor implements PipelineProcessor {
  @override
  PreprocessingStepId get stepId => PreprocessingStepId.contrastEnhancement;

  @override
  Future<void> process(PipelineState state, PreprocessingOptions options) async {
    if (!options.includes(stepId)) return;

    final sw = Stopwatch()..start();
    var applied = false;
    String? message;

    try {
      state.image = img.adjustColor(
        state.image,
        contrast: 1.15,
        brightness: 1.03,
        gamma: 0.95,
      );
      applied = true;
    } catch (e) {
      message = e.toString();
    }

    state.results.add(
      PreprocessingStepResult(
        step: stepId,
        durationMs: sw.elapsedMilliseconds,
        applied: applied,
        message: message,
      ),
    );
  }
}
