import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:snapstudy/features/preprocessing/data/pipeline/image_preprocessing_pipeline.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_state.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_result.dart';

class _MarkAppliedProcessor implements PipelineProcessor {
  _MarkAppliedProcessor(this.id);

  final PreprocessingStepId id;

  @override
  PreprocessingStepId get stepId => id;

  @override
  Future<void> process(PipelineState state, PreprocessingOptions options) async {
    if (!options.includes(stepId)) return;
    state.results.add(
      PreprocessingStepResult(
        step: stepId,
        durationMs: 1,
        applied: true,
      ),
    );
  }
}

void main() {
  test('pipeline runs processors in order', () async {
    final image = img.Image(width: 100, height: 100);
    img.fill(image, color: img.ColorRgb8(240, 240, 240));

    final pipeline = ImagePreprocessingPipeline(
      processors: [
        _MarkAppliedProcessor(PreprocessingStepId.edgeDetection),
        _MarkAppliedProcessor(PreprocessingStepId.autoCrop),
      ],
    );

    final state = await pipeline.run(
      PipelineState(image),
      const PreprocessingOptions(
        steps: [
          PreprocessingStepId.edgeDetection,
          PreprocessingStepId.autoCrop,
        ],
      ),
    );

    expect(state.results.length, 2);
    expect(state.results[0].step, PreprocessingStepId.edgeDetection);
    expect(state.results[1].step, PreprocessingStepId.autoCrop);
  });
}
