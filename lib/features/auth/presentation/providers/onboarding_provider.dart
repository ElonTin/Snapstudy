import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/storage/hive_service.dart';

/// Tracks whether the user completed first-run onboarding.
class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return HiveService.settingsBox.get(StorageKeys.onboardingCompleted)
            as bool? ??
        false;
  }

  Future<void> complete() async {
    state = true;
    await HiveService.settingsBox.put(StorageKeys.onboardingCompleted, true);
  }

  Future<void> reset() async {
    state = false;
    await HiveService.settingsBox.put(StorageKeys.onboardingCompleted, false);
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);
