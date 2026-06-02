import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessed_image.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/preprocessing_options.dart';

abstract interface class ImagePreprocessingRepository {
  Future<Result<PreprocessedImage>> preprocess(
    String sourcePath, {
    PreprocessingOptions options = const PreprocessingOptions(),
  });
}
