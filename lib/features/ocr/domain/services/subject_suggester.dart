import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

/// Suggests a subject from OCR keywords and existing subjects.
class SubjectSuggestion {
  const SubjectSuggestion({
    this.subjectId,
    this.subjectName,
    this.confidence = 0,
  });

  final String? subjectId;
  final String? subjectName;
  final double confidence;
}

abstract final class SubjectSuggester {
  static SubjectSuggestion suggest({
    required List<String> keywords,
    required List<Subject> subjects,
    String? currentSubjectId,
    Map<String, double> tfIdfScores = const {},
  }) {
    if (subjects.isEmpty) return const SubjectSuggestion();

    Subject? best;
    var bestScore = 0.0;

    for (final subject in subjects) {
      if (subject.isDeleted) continue;
      final name = subject.name.toLowerCase();
      var score = 0.0;

      for (final keyword in keywords) {
        final tfidf = tfIdfScores[keyword] ?? 1.0;
        if (name.contains(keyword) || keyword.contains(name)) {
          score += 2.5 * tfidf;
        }
      }

      for (final word in name.split(RegExp(r'\s+'))) {
        if (word.length >= 3 && keywords.contains(word)) {
          score += 1.5 * (tfIdfScores[word] ?? 1.0);
        }
      }

      for (final entry in tfIdfScores.entries) {
        if (name.contains(entry.key)) {
          score += entry.value * 0.5;
        }
      }

      if (subject.id == currentSubjectId) score += 0.5;

      if (score > bestScore) {
        bestScore = score;
        best = subject;
      }
    }

    if (best == null || bestScore < 1.5) {
      return const SubjectSuggestion();
    }

    return SubjectSuggestion(
      subjectId: best.id,
      subjectName: best.name,
      confidence: (bestScore / 8).clamp(0, 1),
    );
  }
}
