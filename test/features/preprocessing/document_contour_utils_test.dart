import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/preprocessing/data/utils/document_contour_utils.dart';
import 'package:snapstudy/features/preprocessing/domain/entities/int_point.dart';

void main() {
  test('orderDocumentQuad sorts corners consistently', () {
    final ordered = orderDocumentQuad([
      const IntPoint(0, 0),
      const IntPoint(100, 0),
      const IntPoint(100, 200),
      const IntPoint(0, 200),
    ]);

    expect(ordered.length, 4);
    expect(ordered.first.x, 0);
    expect(ordered.first.y, 0);
    expect(ordered[1].x, 100);
    expect(ordered[2].x, 100);
    expect(ordered[2].y, 200);
  });

  test('quadOutputSize returns positive dimensions', () {
    const ordered = [
      IntPoint(0, 0),
      IntPoint(300, 0),
      IntPoint(300, 400),
      IntPoint(0, 400),
    ];
    final (w, h) = quadOutputSize(ordered);
    expect(w, greaterThan(0));
    expect(h, greaterThan(0));
  });
}
