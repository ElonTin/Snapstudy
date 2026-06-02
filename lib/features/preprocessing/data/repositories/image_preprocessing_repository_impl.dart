import 'dart:io';

import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/image_preprocessing_pipeline.dart';
import 'package:snapstudy/features/preprocessing/data/pipeline/pipeline_state.dart';
import 'package:snapstudy/features/preprocessing/data/services/image_io_service.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessed_image.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/repositories/image_preprocessing_repository.dart';

class ImagePreprocessingRepositoryImpl implements ImagePreprocessingRepository {
  ImagePreprocessingRepositoryImpl({
    ImagePreprocessingPipeline? pipeline,
    ImageIoService? io,
  })  : _pipeline = pipeline ?? ImagePreprocessingPipeline(),
        _io = io ?? ImageIoService();

  final ImagePreprocessingPipeline _pipeline;
  final ImageIoService _io;

  @override
  Future<Result<PreprocessedImage>> preprocess(
    String sourcePath, {
    PreprocessingOptions options = const PreprocessingOptions(),
  }) async {
    if (!options.enabled) {
      return Success(
        PreprocessedImage(
          sourcePath: sourcePath,
          outputPath: sourcePath,
          steps: const [],
          totalDurationMs: 0,
        ),
      );
    }

    final file = File(sourcePath);
    if (!await file.exists()) {
      return Error(ValidationFailure('Ảnh không tồn tại: $sourcePath'));
    }

    final totalSw = Stopwatch()..start();

    try {
      final decoded = await _io.decodeFile(sourcePath);
      if (decoded == null) {
        return Error(ValidationFailure('Không đọc được ảnh.'));
      }

      final state = await _pipeline.run(PipelineState(decoded), options);
      final outputPath = await _io.encodeJpeg(state.image, sourcePath);

      return Success(
        PreprocessedImage(
          sourcePath: sourcePath,
          outputPath: outputPath,
          steps: List.unmodifiable(state.results),
          totalDurationMs: totalSw.elapsedMilliseconds,
        ),
      );
    } catch (e) {
      AppLogger.warning('Preprocessing failed, using original image', e);
      return Success(
        PreprocessedImage(
          sourcePath: sourcePath,
          outputPath: sourcePath,
          steps: const [],
          totalDurationMs: totalSw.elapsedMilliseconds,
        ),
      );
    }
  }
}
