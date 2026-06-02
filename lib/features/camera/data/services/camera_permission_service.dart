import 'package:permission_handler/permission_handler.dart';

/// Runtime camera and gallery permissions for Android.
class CameraPermissionService {
  Future<bool> ensureCameraGranted() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> ensureGalleryGranted() async {
    if (await _photosGranted()) return true;

    final storage = await Permission.storage.request();
    if (storage.isGranted) return true;

    return _photosGranted();
  }

  Future<bool> _photosGranted() async {
    final photos = await Permission.photos.status;
    if (photos.isGranted) return true;
    final requested = await Permission.photos.request();
    return requested.isGranted;
  }
}
