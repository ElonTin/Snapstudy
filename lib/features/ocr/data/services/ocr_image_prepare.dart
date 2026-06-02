import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:snapstudy/features/camera/domain/constants/camera_constants.dart';

/// Encodes a capture for cloud vision OCR (high-res JPEG, size-capped).
class OcrImagePayload {
  const OcrImagePayload({
    required this.bytes,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String mimeType;
}

abstract final class OcrImagePrepare {
  OcrImagePrepare._();

  static Future<OcrImagePayload?> fromPath(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      final raw = await file.readAsBytes();
      if (raw.isEmpty) return null;

      var decoded = img.decodeImage(raw);
      if (decoded == null) {
        return OcrImagePayload(bytes: Uint8List.fromList(raw), mimeType: 'image/jpeg');
      }

      decoded = _resizeIfNeeded(decoded);
      final jpg = img.encodeJpg(
        decoded,
        quality: CameraConstants.ocrJpegQuality,
      );
      return OcrImagePayload(bytes: Uint8List.fromList(jpg), mimeType: 'image/jpeg');
    } catch (_) {
      return null;
    }
  }

  static img.Image _resizeIfNeeded(img.Image source) {
    final maxEdge = CameraConstants.ocrMaxEdge;
    final w = source.width;
    final h = source.height;
    if (w <= maxEdge && h <= maxEdge) return source;

    if (w >= h) {
      return img.copyResize(source, width: maxEdge);
    }
    return img.copyResize(source, height: maxEdge);
  }
}
