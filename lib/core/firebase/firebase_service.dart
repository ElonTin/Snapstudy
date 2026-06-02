import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/utils/logger.dart';
import 'package:snapstudy/features/notifications/data/services/fcm_background_handler.dart';
import 'package:snapstudy/firebase_options.dart';

/// Firebase bootstrap — enabled only when `ENABLE_FIREBASE=true` in `.env`.
abstract final class FirebaseService {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (!EnvConfig.enableFirebase) {
      AppLogger.info('Firebase disabled via env — skipping init');
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      if (EnvConfig.enableFcm) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      }
      AppLogger.info('Firebase initialized');
    } catch (e, st) {
      AppLogger.warning(
        'Firebase init failed — add google-services.json and run flutterfire configure',
        e,
      );
      AppLogger.debug('Firebase stack', e, st);
    }
  }
}
