import 'package:image/image.dart' as img;
import 'package:snapstudy/features/preprocessing/domain/entities/int_point.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_result.dart';

/// Mutable state passed through the preprocessing pipeline.
class PipelineState {
  PipelineState(this.image);

  img.Image image;
  img.Image? edgeMap;
  List<IntPoint>? documentQuad;
  bool perspectiveApplied = false;
  final List<PreprocessingStepResult> results = [];
}
