import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/camera/presentation/widgets/document_crop_overlay.dart';

void main() {
  testWidgets('DocumentCropOverlay renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DocumentCropOverlay(),
        ),
      ),
    );

    expect(find.byType(DocumentCropOverlay), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DocumentCropOverlay),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}
