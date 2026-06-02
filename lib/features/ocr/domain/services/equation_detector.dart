/// Detects math/equation patterns in lecture text (Mathpix — later phase).
abstract final class EquationDetector {
  static final _patterns = [
    RegExp(r'[0-9]+\s*[\+\-\×÷*/=]\s*[0-9]+'),
    RegExp(r'\^[0-9n]'),
    RegExp(r'\\frac|\\sum|\\int|\\sqrt'),
    RegExp(r'[∫∑√πθαβλμ]'),
    RegExp(r'[a-zA-Z]\s*=\s*[^=]+'),
    RegExp(r'\([a-zA-Z]\)'),
  ];

  static bool containsEquations(String text) {
    if (text.trim().isEmpty) return false;
    for (final pattern in _patterns) {
      if (pattern.hasMatch(text)) return true;
    }
    return false;
  }
}
