import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/home/domain/entities/study_progress.dart';
import 'package:snapstudy/features/home/presentation/widgets/progress_stats_row.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  testWidgets('shows weekly sessions and goal percent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProgressStatsRow(
            progress: StudyProgress(
              sessionsThisWeek: 4,
              cardsReviewed: 12,
              studyMinutesToday: 30,
              streakDays: 3,
              weeklyGoalPercent: 0.75,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ProgressStatsRow), findsOneWidget);
    expect(find.text('Buổi học'), findsOneWidget);
    expect(find.text('Thẻ ôn'), findsOneWidget);
    expect(find.text('Mục tiêu'), findsOneWidget);
  });
}
