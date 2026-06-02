import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ocr/domain/services/equation_detector.dart';

void main() {
  test('detects equation patterns', () {
    expect(
      EquationDetector.containsEquations('f(x) = x^2 + 2x + 1'),
      isTrue,
    );
    expect(
      EquationDetector.containsEquations('Chào các bạn học sinh'),
      isFalse,
    );
  });
}
