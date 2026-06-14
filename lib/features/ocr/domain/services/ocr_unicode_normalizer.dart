/// Chuẩn hóa ký tự đặc biệt / Unicode sau OCR.
abstract final class OcrUnicodeNormalizer {
  static String normalize(String text) {
    if (text.isEmpty) return text;

    var s = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\u00A0', ' ')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('…', '...')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('•', '• ')
        .replaceAll('ﬁ', 'fi')
        .replaceAll('ﬂ', 'fl');

    const mathSymbols = {
      '×': r'\times',
      '÷': r'\div',
      '≤': r'\leq',
      '≥': r'\geq',
      '≠': r'\neq',
      '≈': r'\approx',
      '∞': r'\infty',
      '√': r'\sqrt',
      'π': r'\pi',
      'α': r'\alpha',
      'β': r'\beta',
      'γ': r'\gamma',
      'θ': r'\theta',
      'λ': r'\lambda',
      'μ': r'\mu',
      'Δ': r'\Delta',
      'Σ': r'\Sigma',
    };

    for (final entry in mathSymbols.entries) {
      if (!s.contains(r'$') && s.contains(entry.key)) {
        s = s.replaceAll(entry.key, entry.value);
      }
    }

    s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }
}
