import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/camera/data/services/camera_permission_service.dart';
import 'package:snapstudy/features/camera/data/services/capture_processing_service.dart';
import 'package:snapstudy/features/camera/data/services/gallery_import_service.dart';
import 'package:snapstudy/features/camera/data/services/image_compress_service.dart';
import 'package:snapstudy/features/preprocessing/presentation/providers/preprocessing_providers.dart';

final cameraPermissionServiceProvider = Provider<CameraPermissionService>(
  (ref) => CameraPermissionService(),
);

final imageCompressServiceProvider = Provider<ImageCompressService>(
  (ref) => ImageCompressService(),
);

final galleryImportServiceProvider = Provider<GalleryImportService>(
  (ref) => GalleryImportService(),
);

final captureProcessingServiceProvider = Provider<CaptureProcessingService>(
  (ref) => CaptureProcessingService(
    compress: ref.watch(imageCompressServiceProvider),
    preprocess: ref.watch(imagePreprocessingRepositoryProvider),
  ),
);
