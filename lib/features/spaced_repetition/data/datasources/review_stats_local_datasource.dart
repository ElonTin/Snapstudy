import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/storage/hive_service.dart';

/// Persists daily review counters & retention EWMA.
class ReviewStatsLocalDataSource {
  void _resetIfNewDay() {
    final today = _dateKey(DateTime.now());
    final stored = HiveService.settingsBox.get(StorageKeys.srReviewsTodayDate);
    if (stored != today) {
      HiveService.settingsBox.put(StorageKeys.srReviewsTodayDate, today);
      HiveService.settingsBox.put(StorageKeys.srReviewsTodayCount, 0);
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int readReviewedToday() {
    _resetIfNewDay();
    return HiveService.settingsBox.get(StorageKeys.srReviewsTodayCount) as int? ??
        0;
  }

  Future<void> incrementReviewedToday() async {
    _resetIfNewDay();
    final count = readReviewedToday() + 1;
    await HiveService.settingsBox.put(StorageKeys.srReviewsTodayCount, count);
    await _updateStreak();
  }

  Future<void> _updateStreak() async {
    final today = _dateKey(DateTime.now());
    final last = HiveService.settingsBox.get(StorageKeys.srLastStudyDate) as String?;
    var streak =
        HiveService.settingsBox.get(StorageKeys.srStreakDays) as int? ?? 0;

    if (last == today) return;

    if (last != null) {
      final lastDate = DateTime.parse(last);
      final diff = DateTime.now().difference(lastDate).inDays;
      streak = diff == 1 ? streak + 1 : 1;
    } else {
      streak = 1;
    }

    await HiveService.settingsBox.put(StorageKeys.srLastStudyDate, today);
    await HiveService.settingsBox.put(StorageKeys.srStreakDays, streak);
  }

  int readStreakDays() {
    return HiveService.settingsBox.get(StorageKeys.srStreakDays) as int? ?? 0;
  }

  double readRetentionEwma() {
    return (HiveService.settingsBox.get(StorageKeys.srRetentionEwma) as num?)
            ?.toDouble() ??
        0.72;
  }

  Future<void> updateRetentionEwma(int quality) async {
    final success = quality >= 3 ? 1.0 : 0.0;
    final prev = readRetentionEwma();
    const alpha = 0.15;
    final next = prev + alpha * (success - prev);
    await HiveService.settingsBox.put(StorageKeys.srRetentionEwma, next);
  }
}
