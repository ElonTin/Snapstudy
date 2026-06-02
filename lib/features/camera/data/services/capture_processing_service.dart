import 'dart:io';

import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/features/camera/data/services/image_compress_service.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/repositories/image_preprocessing_repository.dart';

/// Compresses then preprocesses a capture (Phase 6 + 7).
class CaptureProcessingService {
  CaptureProcessingService({
    required ImageCompressService compress,
    required ImagePreprocessingRepository preprocess,
  })  : _compress = compress,
        _preprocess = preprocess;

  final ImageCompressService _compress;
  final ImagePreprocessingRepository _preprocess;

  Future<String> processCapture(String sourcePath) async {
    try {
      if (!await File(sourcePath).exists()) return sourcePath;

      var current = await _compress.compress(sourcePath);
      if (!await File(current).exists()) return sourcePath;

      if (!EnvConfig.enablePreprocessing) return current;

      final result = await _preprocess.preprocess(
        current,
        options: PreprocessingOptions.forOcr,
      );

      return result.fold(
        onSuccess: (processed) async {
          final out = processed.outputPath;
          if (out != current && await File(current).exists()) {
            try {
              await File(current).delete();
            } catch (_) {}
          }
          return await File(out).exists() ? out : current;
        },
        onFailure: (_) => current,
      );
    } catch (_) {
      return sourcePath;
    }
  }
}
