import 'package:image_picker/image_picker.dart';

/// Imports one or more images from the device gallery.
class GalleryImportService {
  GalleryImportService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<List<String>> pickMultiple({int imageQuality = 85}) async {
    final files = await _picker.pickMultiImage(imageQuality: imageQuality);
    return files.map((f) => f.path).toList();
  }

  Future<String?> pickSingle({int imageQuality = 85}) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
    );
    return file?.path;
  }
}
