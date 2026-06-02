import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_state.dart';
import 'package:snapstudy/features/preprocessing/data/utils/image_pipeline_helpers.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_result.dart';

/// Edge detection (Sobel) + document bounds discovery.
class EdgeDetectionProcessor implements PipelineProcessor {
  @override
  PreprocessingStepId get stepId => PreprocessingStepId.edgeDetection;

  @override
  Future<void> process(PipelineState state, PreprocessingOptions options) async {
    if (!options.includes(stepId)) return;

    final sw = Stopwatch()..start();
    var applied = false;
    String? message;

    try {
      state.edgeMap = computeEdgeMap(state.image);
      final quad = findDocumentQuadFromEdges(state.edgeMap!);
      if (quad != null) {
        state.documentQuad = quad;
        applied = true;
      } else {
        message = 'Không phát hiện vùng tài liệu rõ';
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
