import 'package:logger/logger.dart';
import 'package:snapstudy/core/env/env_config.dart';

/// Centralized logging — verbose in development, quiet in production.
abstract final class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
    level: EnvConfig.isDevelopment ? Level.debug : Level.warning,
  );

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message) => _logger.i(message);

  static void warning(String message, [Object? error]) {
    _logger.w(message, error: error);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
