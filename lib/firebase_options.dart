// File generated for Firebase project snapstudy-6fbd2.
// Re-run `flutterfire configure` after adding iOS or Web apps.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for SNAPSTUDY.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions chưa cấu hình cho Web — chạy flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions chưa cấu hình cho iOS — thêm app iOS trên Firebase Console.',
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions chỉ hỗ trợ Android trong bản cấu hình hiện tại.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions không hỗ trợ platform này.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAdfBKgfahl06YnYdLN4hDL48Hbpj58xXg',
    appId: '1:1009954961371:android:3f19081766c7403c7599fe',
    messagingSenderId: '1009954961371',
    projectId: 'snapstudy-6fbd2',
    storageBucket: 'snapstudy-6fbd2.firebasestorage.app',
  );
}
