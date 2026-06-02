import 'package:image/image.dart' as img;
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_state.dart';
import 'package:snapstudy/features/preprocessing/data/utils/document_contour_utils.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_result.dart';

/// Crops to detected document bounds (perspective warp when OpenCV native is enabled).
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
        final left = ordered.map((p) => p.x).reduce((a, b) => a < b ? a : b);
        final top = ordered.map((p) => p.y).reduce((a, b) => a < b ? a : b);
        final right = ordered.map((p) => p.x).reduce((a, b) => a > b ? a : b);
        final bottom = ordered.map((p) => p.y).reduce((a, b) => a > b ? a : b);

        final w = (right - left).clamp(1, state.image.width - left);
        final h = (bottom - top).clamp(1, state.image.height - top);

        state.image = img.copyCrop(
          state.image,
          x: left,
          y: top,
          width: w,
          height: h,
        );
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
