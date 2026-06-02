import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_state.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';

/// Single async step in the preprocessing pipeline.
abstract class PipelineProcessor {
  PreprocessingStepId get stepId;

  Future<void> process(
    PipelineState state,
    PreprocessingOptions options,
  );
}
