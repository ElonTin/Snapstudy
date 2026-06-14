import 'dart:io';

import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/features/camera/data/services/image_compress_service.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';
import 'package:snapstudy/features/preprocessing/domain/repositories/image_preprocessing_repository.dart';

/// Chuẩn bị ảnh chụp/import: lưu bản gốc (nén nhẹ) và tùy chọn tiền xử lý OCR tạm.
class CaptureProcessingService {
  CaptureProcessingService({
    required ImageCompressService compress,
    required ImagePreprocessingRepository preprocess,
  })  : _compress = compress,
        _preprocess = preprocess;

  final ImageCompressService _compress;
  final ImagePreprocessingRepository _preprocess;

  /// Nén nhẹ để lưu buổi học — giữ màu gốc, không warp/crop.
  Future<String> prepareForStorage(String sourcePath) async {
    try {
      if (!await File(sourcePath).exists()) return sourcePath;
      final compressed = await _compress.compress(sourcePath);
      return await File(compressed).exists() ? compressed : sourcePath;
    } catch (_) {
      return sourcePath;
    }
  }

  /// Alias cho luồng addCapture (chỉ nén, không làm hỏng ảnh hiển thị).
  Future<String> processCapture(String sourcePath) =>
      prepareForStorage(sourcePath);

  /// Tạo bản sao tạm chỉ dùng cho OCR (không ghi đè ảnh đã lưu).
  Future<String> prepareOcrInput(String storedPath) async {
    try {
      if (!EnvConfig.enablePreprocessing) return storedPath;
      if (!await File(storedPath).exists()) return storedPath;

      final result = await _preprocess.preprocess(
        storedPath,
        options: PreprocessingOptions.forOcr,
      );

      return result.fold(
        onSuccess: (processed) async {
          final out = processed.outputPath;
          return out != storedPath && await File(out).exists()
              ? out
              : storedPath;
        },
        onFailure: (_) => storedPath,
      );
    } catch (_) {
      return storedPath;
    }
  }
}
