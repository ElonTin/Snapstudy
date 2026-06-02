import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:snapstudy/features/camera/domain/constants/camera_constants.dart';

/// Compresses captures for fast upload and OCR (Phase 8).
class ImageCompressService {
  Future<String> compress(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;

    final dir = source.parent.path;
    final base = p.basenameWithoutExtension(sourcePath);
    final targetPath = p.join(
      dir,
      '${base}_cmp_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: CameraConstants.compressQuality,
      minWidth: CameraConstants.compressMaxEdge,
      minHeight: CameraConstants.compressMaxEdge,
      format: CompressFormat.jpeg,
    );

    if (result == null) return sourcePath;

    try {
      if (sourcePath != result.path && await source.exists()) {
        await source.delete();
      }
    } catch (_) {
      // Keep original if cleanup fails.
    }

    return result.path;
  }
}
