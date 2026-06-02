import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_state.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/processors/auto_crop_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/processors/contrast_enhancement_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/processors/edge_detection_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/processors/noise_reduction_processor.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/processors/perspective_correction_processor.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';

/// Ordered OpenCV preprocessing pipeline.
class ImagePreprocessingPipeline {
  ImagePreprocessingPipeline({List<PipelineProcessor>? processors})
      : _processors = processors ?? _defaultProcessors;

  static final _defaultProcessors = <PipelineProcessor>[
    EdgeDetectionProcessor(),
    PerspectiveCorrectionProcessor(),
    AutoCropProcessor(),
    ContrastEnhancementProcessor(),
    NoiseReductionProcessor(),
  ];

  final List<PipelineProcessor> _processors;

  Future<PipelineState> run(
    PipelineState state,
    PreprocessingOptions options,
  ) async {
    for (final processor in _processors) {
      await processor.process(state, options);
    }
    return state;
  }
}
