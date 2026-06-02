enum QuizDifficulty { easy, medium, hard }

extension QuizDifficultyX on QuizDifficulty {
  String get label => switch (this) {
        QuizDifficulty.easy => 'Dễ',
        QuizDifficulty.medium => 'Trung bình',
        QuizDifficulty.hard => 'Khó',
      };

  static QuizDifficulty? tryParse(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toLowerCase();
    return switch (normalized) {
      'easy' || 'dễ' || 'de' => QuizDifficulty.easy,
      'medium' || 'trung bình' || 'trungbinh' || 'normal' =>
        QuizDifficulty.medium,
      'hard' || 'khó' || 'kho' || 'difficult' => QuizDifficulty.hard,
      _ => null,
    };
  }
}
