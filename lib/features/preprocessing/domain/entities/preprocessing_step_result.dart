import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_step_id.dart';

class PreprocessingStepResult extends Equatable {
  const PreprocessingStepResult({
    required this.step,
    required this.durationMs,
    required this.applied,
    this.message,
  });

  final PreprocessingStepId step;
  final int durationMs;
  final bool applied;
  final String? message;

  @override
  List<Object?> get props => [step, durationMs, applied, message];
}
