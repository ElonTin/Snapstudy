import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/preprocessing/data/repositories/image_preprocessing_repository_impl.dart';
import 'package:snapstudy/features/preprocessing/domain/repositories/image_preprocessing_repository.dart';

final imagePreprocessingRepositoryProvider =
    Provider<ImagePreprocessingRepository>(
  (ref) => ImagePreprocessingRepositoryImpl(),
);
