import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Tunable performance defaults (overridable via `.env`).
abstract final class PerformanceConfig {
  static int _intEnv(String key, String fallback) {
    try {
      return int.tryParse(dotenv.env[key] ?? fallback) ?? int.parse(fallback);
    } catch (_) {
      return int.parse(fallback);
    }
  }

  static Duration get dashboardCacheTtl =>
      Duration(seconds: _intEnv('DASHBOARD_CACHE_TTL_SECONDS', '45'));

  static Duration get sessionListCacheTtl =>
      Duration(seconds: _intEnv('SESSION_LIST_CACHE_TTL_SECONDS', '30'));

  static int get imageCacheMaxMb => _intEnv('IMAGE_CACHE_MAX_MB', '120');

  static int get imageCacheMaxImages => _intEnv('IMAGE_CACHE_MAX_COUNT', '200');

  static int get captureThumbnailCacheWidth => 400;
}
