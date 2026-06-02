/// Extracts study keywords from OCR text.
abstract final class KeywordExtractor {
  static const _stopWords = {
    'và', 'của', 'là', 'có', 'trong', 'cho', 'với', 'một', 'các', 'được',
    'the', 'and', 'or', 'a', 'an', 'to', 'in', 'on', 'for', 'is', 'are',
    'this', 'that', 'it', 'be', 'as', 'at', 'by', 'from',
  };

  static List<String> extract(String text, {int maxKeywords = 12}) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');

    final counts = <String, int>{};
    for (final raw in normalized.split(RegExp(r'\s+'))) {
      final word = raw.trim();
      if (word.length < 3 || _stopWords.contains(word)) continue;
      counts[word] = (counts[word] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(maxKeywords).map((e) => e.key).toList();
  }
}
