import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';

void main() {
  test('default options include all pipeline steps', () {
    const options = PreprocessingOptions();
    expect(options.enabled, isTrue);
    expect(options.steps, PreprocessingOptions.defaultSteps);
    expect(options.includes(PreprocessingStepId.edgeDetection), isTrue);
    expect(options.includes(PreprocessingStepId.noiseReduction), isTrue);
  });

  test('disabled options has no steps', () {
    expect(PreprocessingOptions.disabled.enabled, isFalse);
    expect(PreprocessingOptions.disabled.steps, isEmpty);
  });
}
