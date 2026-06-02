import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/home/presentation/widgets/review_reminder_banner.dart';
import 'package:snapstudy/features/spaced_repetition/domain/entities/spaced_repetition_stats.dart';
import 'package:snapstudy/features/spaced_repetition/presentation/providers/spaced_repetition_providers.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  testWidgets('hides banner when no cards due', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spacedRepetitionStatsProvider.overrideWith(
            (ref) async => const SpacedRepetitionStats(
              dueNow: 0,
              dueToday: 0,
              overdue: 0,
              reviewedToday: 0,
              retentionPercent: 80,
              averageDifficulty: 50,
              nextReminderAt: null,
              studyStreakDays: 1,
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ReviewReminderBanner())),
      ),
    );
    await tester.pump();

    expect(find.textContaining('thẻ cần ôn'), findsNothing);
  });

  testWidgets('shows banner when cards are due', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spacedRepetitionStatsProvider.overrideWith(
            (ref) async => const SpacedRepetitionStats(
              dueNow: 5,
              dueToday: 5,
              overdue: 2,
              reviewedToday: 1,
              retentionPercent: 72,
              averageDifficulty: 45,
              nextReminderAt: null,
              studyStreakDays: 2,
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ReviewReminderBanner())),
      ),
    );
    await tester.pump();

    expect(find.text('5 thẻ cần ôn ngay'), findsOneWidget);
    expect(find.textContaining('quá hạn'), findsOneWidget);
  });
}
