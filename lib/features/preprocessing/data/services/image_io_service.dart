import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Loads and saves JPEG images for the pipeline.
class ImageIoService {
  Future<img.Image?> decodeFile(String path) async {
    final bytes = await File(path).readAsBytes();
    return img.decodeImage(bytes);
  }

  Future<String> encodeJpeg(img.Image image, String sourcePath) async {
    final dir = p.dirname(sourcePath);
    final base = p.basenameWithoutExtension(sourcePath);
    final outPath = p.join(
      dir,
      '${base}_pre_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final bytes = Uint8List.fromList(img.encodeJpg(image, quality: 90));
    await File(outPath).writeAsBytes(bytes);
    return outPath;
  }
}
