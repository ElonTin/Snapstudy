import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';

/// Configures which preprocessing steps run.
class PreprocessingOptions {
  const PreprocessingOptions({
    this.enabled = true,
    this.steps = PreprocessingOptions.defaultSteps,
  });

  static const List<PreprocessingStepId> defaultSteps = [
    PreprocessingStepId.edgeDetection,
    PreprocessingStepId.perspectiveCorrection,
    PreprocessingStepId.autoCrop,
    PreprocessingStepId.contrastEnhancement,
    PreprocessingStepId.noiseReduction,
  ];

  final bool enabled;
  final List<PreprocessingStepId> steps;

  bool includes(PreprocessingStepId step) => steps.contains(step);

  static const PreprocessingOptions disabled =
      PreprocessingOptions(enabled: false, steps: []);

  /// Light touch before OCR — avoids aggressive crop that can clip text.
  static const PreprocessingOptions forOcr = PreprocessingOptions(
    steps: [
      PreprocessingStepId.contrastEnhancement,
    ],
  );
}
