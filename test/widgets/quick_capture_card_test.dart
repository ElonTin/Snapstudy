import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/home/presentation/widgets/quick_capture_card.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  testWidgets('tap invokes onCapture callback', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickCaptureCard(onCapture: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Bắt đầu chụp'), findsOneWidget);
    await tester.tap(find.text('Bắt đầu chụp'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
