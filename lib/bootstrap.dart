import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/app.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/firebase/firebase_service.dart';
import 'package:snapstudy/core/performance/memory_tuning.dart';
import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/core/utils/logger.dart';

/// Application bootstrap — minimal blocking work before first frame.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  MemoryTuning.apply();

  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  );

  await Future.wait([
    EnvConfig.load(),
    HiveService.init(),
  ]);

  AppLogger.info('SNAPSTUDY bootstrap complete [${EnvConfig.environment}]');

  runApp(
    const ProviderScope(
      child: SnapStudyApp(),
    ),
  );

  // Non-blocking — must not delay runApp / first frame.
  unawaited(FirebaseService.init());
}
