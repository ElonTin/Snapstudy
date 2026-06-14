import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/home/presentation/widgets/quick_capture_card.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  testWidgets('tap Chụp bài invokes onCapture', (tester) async {
    var captureTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickCaptureCard(
            onCapture: () => captureTapped = true,
            onGalleryImport: () {},
          ),
        ),
      ),
    );

    expect(find.text('Chụp bài'), findsOneWidget);
    await tester.tap(find.text('Chụp bài'));
    await tester.pump();

    expect(captureTapped, isTrue);
  });

  testWidgets('tap Import ảnh invokes onGalleryImport', (tester) async {
    var galleryTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickCaptureCard(
            onCapture: () {},
            onGalleryImport: () => galleryTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Import ảnh'), findsOneWidget);
    await tester.tap(find.text('Import ảnh'));
    await tester.pump();

    expect(galleryTapped, isTrue);
  });
}
