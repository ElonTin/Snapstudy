import 'package:hive_flutter/hive_flutter.dart';
import 'package:snapstudy/core/storage/hive_boxes.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_storage_migration.dart';
import 'package:snapstudy/core/utils/logger.dart';

/// Initializes and exposes Hive boxes for local persistence.
abstract final class HiveService {
  static late Box<dynamic> settingsBox;
  static late Box<dynamic> cacheBox;
  static late Box<dynamic> subjectsBox;
  static late Box<dynamic> sessionsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    settingsBox = await Hive.openBox(HiveBoxes.settings);
    cacheBox = await Hive.openBox(HiveBoxes.cache);
    subjectsBox = await Hive.openBox(HiveBoxes.subjects);
    sessionsBox = await Hive.openBox(HiveBoxes.sessions);
    await SessionStorageMigration.runIfNeeded(
      sessionsBox: sessionsBox,
      settingsBox: settingsBox,
    );
    AppLogger.info('Hive initialized');
  }

  static Future<void> clearCache() async {
    await cacheBox.clear();
  }
}
