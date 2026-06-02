import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/camera/domain/constants/camera_constants.dart';

void main() {
  test('crop guide fractions are valid', () {
    expect(CameraConstants.cropGuideWidthFraction, greaterThan(0));
    expect(CameraConstants.cropGuideWidthFraction, lessThanOrEqualTo(1));
    expect(CameraConstants.cropGuideHeightFraction, greaterThan(0));
    expect(CameraConstants.cropGuideHeightFraction, lessThanOrEqualTo(1));
  });

  test('compression settings are production defaults', () {
    expect(CameraConstants.compressMaxEdge, 1920);
    expect(CameraConstants.compressQuality, inInclusiveRange(1, 100));
  });
}
