import 'package:flutter/painting.dart';
import 'package:snapstudy/core/performance/performance_config.dart';

/// Applies global Flutter image cache limits to reduce memory pressure.
abstract final class MemoryTuning {
  static void apply() {
    final maxBytes = PerformanceConfig.imageCacheMaxMb * 1024 * 1024;
    PaintingBinding.instance.imageCache.maximumSizeBytes = maxBytes;
    PaintingBinding.instance.imageCache.maximumSize =
        PerformanceConfig.imageCacheMaxImages;
  }

  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}
