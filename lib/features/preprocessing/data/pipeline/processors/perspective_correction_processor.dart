import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_state.dart';
import 'package:snapstudy/features/preprocessing/data/utils/document_contour_utils.dart';
import 'package:snapstudy/features/preprocessing/data/utils/image_pipeline_helpers.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_result.dart';

/// Perspective warp from detected document quad to flat rectangle.
class PerspectiveCorrectionProcessor implements PipelineProcessor {
  @override
  PreprocessingStepId get stepId => PreprocessingStepId.perspectiveCorrection;

  @override
  Future<void> process(PipelineState state, PreprocessingOptions options) async {
    if (!options.includes(stepId)) return;

    final sw = Stopwatch()..start();
    var applied = false;
    String? message;

    try {
      final quad = state.documentQuad;
      if (quad == null || quad.length != 4) {
        message = 'Bỏ qua — chưa có khung tài liệu';
      } else {
        final ordered = orderDocumentQuad(quad);
        state.image = warpPerspective(state.image, ordered);
        state.perspectiveApplied = true;
        applied = true;
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
