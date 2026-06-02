import 'package:image/image.dart' as img;
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_state.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_result.dart';

/// Gaussian smoothing — reduces sensor noise while keeping edges.
class NoiseReductionProcessor implements PipelineProcessor {
  @override
  PreprocessingStepId get stepId => PreprocessingStepId.noiseReduction;

  @override
  Future<void> process(PipelineState state, PreprocessingOptions options) async {
    if (!options.includes(stepId)) return;

    final sw = Stopwatch()..start();
    var applied = false;
    String? message;

    try {
      state.image = img.gaussianBlur(state.image, radius: 1);
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
