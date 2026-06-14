import 'dart:math' as math;

/// Extracts study keywords from OCR text (frequency + TF-IDF).
abstract final class KeywordExtractor {
  static const _stopWords = {
    'và', 'của', 'là', 'có', 'trong', 'cho', 'với', 'một', 'các', 'được',
    'the', 'and', 'or', 'a', 'an', 'to', 'in', 'on', 'for', 'is', 'are',
    'this', 'that', 'it', 'be', 'as', 'at', 'by', 'from',
  };

  static List<String> extract(String text, {int maxKeywords = 12}) =>
      extractTfIdf(text, maxKeywords: maxKeywords);

  static List<String> extractTfIdf(
    String text, {
    List<String> corpusDocuments = const [],
    int maxKeywords = 12,
  }) {
    final scores = scoreTerms(text, corpusDocuments: corpusDocuments);
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(maxKeywords).map((e) => e.key).toList();
  }

  /// TF × IDF scores for each term in [text] against [corpusDocuments].
  static Map<String, double> scoreTerms(
    String text, {
    List<String> corpusDocuments = const [],
  }) {
    final docTerms = _tokenize(text);
    if (docTerms.isEmpty) return {};

    final tf = <String, int>{};
    for (final term in docTerms) {
      tf[term] = (tf[term] ?? 0) + 1;
    }

    final corpus = corpusDocuments.isEmpty
        ? [text]
        : [...corpusDocuments, text];

    final scores = <String, double>{};
    final docCount = corpus.length;

    for (final entry in tf.entries) {
      final term = entry.key;
      var df = 0;
      for (final doc in corpus) {
        if (_tokenize(doc).contains(term)) df++;
      }
      final idf = math.log((docCount + 1) / (df + 1)) + 1;
      scores[term] = entry.value * idf;
    }

    return scores;
  }

  static List<String> _tokenize(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');

    return normalized
        .split(RegExp(r'\s+'))
        .map((w) => w.trim())
        .where((w) => w.length >= 3 && !_stopWords.contains(w))
        .toList();
  }
}
