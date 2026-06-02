import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_result.dart';

class PreprocessedImage extends Equatable {
  const PreprocessedImage({
    required this.sourcePath,
    required this.outputPath,
    required this.steps,
    required this.totalDurationMs,
  });

  final String sourcePath;
  final String outputPath;
  final List<PreprocessingStepResult> steps;
  final int totalDurationMs;

  bool get wasProcessed => outputPath != sourcePath || steps.any((s) => s.applied);

  @override
  List<Object?> get props => [sourcePath, outputPath, steps, totalDurationMs];
}
