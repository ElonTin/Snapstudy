import 'package:image/image.dart' as img;
import 'package:snapstudy/features/camera/domain/constants/camera_constants.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_state.dart';
import 'package:snapstudy/features/preprocessing/data/utils/image_pipeline_helpers.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_result.dart';

/// Trims borders to content or camera guide frame.
class AutoCropProcessor implements PipelineProcessor {
  @override
  PreprocessingStepId get stepId => PreprocessingStepId.autoCrop;

  @override
  Future<void> process(PipelineState state, PreprocessingOptions options) async {
    if (!options.includes(stepId)) return;

    final sw = Stopwatch()..start();
    var applied = false;
    String? message;

    try {
      if (state.perspectiveApplied) {
        final cropped = cropToContentBounds(state.image);
        if (cropped != null) {
          state.image = cropped;
          applied = true;
        }
      } else {
        final w = state.image.width;
        final h = state.image.height;
        final cw = (w * CameraConstants.cropGuideWidthFraction).round();
        final ch = (h * CameraConstants.cropGuideHeightFraction).round();
        final x = ((w - cw) / 2).round();
        final y = ((h - ch) / 2).round();
        state.image = img.copyCrop(state.image, x: x, y: y, width: cw, height: ch);
        applied = true;
        message = 'Crop theo khung hướng dẫn camera';
      }
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
