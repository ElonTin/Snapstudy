/// Extracts LaTeX-like equation strings from OCR plain text.
abstract final class LatexEquationExtractor {
  static final _inlinePatterns = [
    RegExp(r'\$\$([^$]+)\$\$'),
    RegExp(r'\$([^$\n]+)\$'),
    RegExp(r'\\\(([^)]+)\\\)'),
    RegExp(r'\\frac\{[^}]+\}\{[^}]+\}'),
    RegExp(r'\\int[^\\s]+'),
    RegExp(r'\\sum[^\\s]+'),
    RegExp(r'[a-zA-Z]\^\{[^}]+\}'),
    RegExp(r'[a-zA-Z]_\{[^}]+\}'),
    RegExp(r'\\sqrt\{[^}]+\}'),
    RegExp(r'\\lim[^\\s]+'),
    RegExp(r'f\s*\(\s*x\s*\)\s*=\s*[^\n]+'),
    RegExp(r'[∫∑√πθαβγΔΣ][^\n]{2,60}'),
  ];

  static List<String> extract(String text, {int maxEquations = 20}) {
    if (text.trim().isEmpty) return const [];

    final found = <String>{};

    for (final pattern in _inlinePatterns) {
      for (final match in pattern.allMatches(text)) {
        var eq = match.groupCount > 0 ? (match.group(1) ?? match.group(0)) : match.group(0);
        eq = eq?.trim();
        if (eq == null || eq.length < 2) continue;
        if (!eq.contains(r'\') && !eq.contains('^') && !eq.contains('=') && eq.length < 6) {
          continue;
        }
        found.add(_normalize(eq));
        if (found.length >= maxEquations) break;
      }
      if (found.length >= maxEquations) break;
    }

    return found.toList();
  }

  static String _normalize(String raw) {
    var s = raw;
    if (!s.startsWith(r'\') && !s.startsWith('\$')) {
      s = s.replaceAll('×', r'\times ').replaceAll('÷', r'\div ');
    }
    return s;
  }
}
