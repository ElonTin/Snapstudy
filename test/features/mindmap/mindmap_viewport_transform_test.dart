import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/mindmap/presentation/utils/mindmap_viewport_transform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fit centers canvas in viewport', () {
    final matrix = MindmapViewportTransform.fit(
      viewport: const Size(400, 300),
      canvas: const Size(800, 600),
    );
    final scale = MindmapViewportTransform.readScale(matrix);
    expect(scale, lessThan(1));
    expect(MindmapViewportTransform.zoomPercent(matrix), greaterThan(0));
  });

  test('zoomAt keeps focal point stable', () {
    const focal = Offset(200, 150);
    final initial = Matrix4.identity()..scaleByDouble(0.8, 0.8, 0.8, 1);
    initial.setTranslationRaw(10, 20, 0);

    final zoomed = MindmapViewportTransform.zoomAt(
      current: initial,
      focal: focal,
      factor: 1.5,
    );

    final beforeScale = MindmapViewportTransform.readScale(initial);
    final afterScale = MindmapViewportTransform.readScale(zoomed);
    expect(afterScale, greaterThan(beforeScale));

    final t0 = initial.getTranslation();
    final sceneX = (focal.dx - t0.x) / beforeScale;
    final sceneY = (focal.dy - t0.y) / beforeScale;

    final t1 = zoomed.getTranslation();
    final mappedBackX = t1.x + sceneX * afterScale;
    final mappedBackY = t1.y + sceneY * afterScale;
    expect(mappedBackX, closeTo(focal.dx, 0.01));
    expect(mappedBackY, closeTo(focal.dy, 0.01));
  });
}
