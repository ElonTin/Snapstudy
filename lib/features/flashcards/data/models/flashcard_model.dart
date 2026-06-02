import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';

class FlashcardModel {
  const FlashcardModel({
    required this.id,
    required this.front,
    required this.back,
    this.hint,
    this.tags = const [],
    this.nextReviewAt,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    this.lapses = 0,
    this.totalReviews = 0,
    this.lastReviewAt,
    this.lastQuality,
    this.difficultyScore = 50,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      hint: json['hint'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      nextReviewAt: json['nextReviewAt'] != null
          ? DateTime.parse(json['nextReviewAt'] as String)
          : null,
      intervalDays: json['intervalDays'] as int? ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      repetitions: json['repetitions'] as int? ?? 0,
      lapses: json['lapses'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      lastReviewAt: json['lastReviewAt'] != null
          ? DateTime.parse(json['lastReviewAt'] as String)
          : null,
      lastQuality: json['lastQuality'] as int?,
      difficultyScore: json['difficultyScore'] as int? ?? 50,
    );
  }

  final String id;
  final String front;
  final String back;
  final String? hint;
  final List<String> tags;
  final DateTime? nextReviewAt;
  final int intervalDays;
  final double easeFactor;
  final int repetitions;
  final int lapses;
  final int totalReviews;
  final DateTime? lastReviewAt;
  final int? lastQuality;
  final int difficultyScore;

  Map<String, dynamic> toJson() => {
        'id': id,
        'front': front,
        'back': back,
        if (hint != null) 'hint': hint,
        'tags': tags,
        if (nextReviewAt != null)
          'nextReviewAt': nextReviewAt!.toIso8601String(),
        'intervalDays': intervalDays,
        'easeFactor': easeFactor,
        'repetitions': repetitions,
        'lapses': lapses,
        'totalReviews': totalReviews,
        if (lastReviewAt != null)
          'lastReviewAt': lastReviewAt!.toIso8601String(),
        if (lastQuality != null) 'lastQuality': lastQuality,
        'difficultyScore': difficultyScore,
      };

  Flashcard toEntity() => Flashcard(
        id: id,
        front: front,
        back: back,
        hint: hint,
        tags: tags,
        nextReviewAt: nextReviewAt,
        intervalDays: intervalDays,
        easeFactor: easeFactor,
        repetitions: repetitions,
        lapses: lapses,
        totalReviews: totalReviews,
        lastReviewAt: lastReviewAt,
        lastQuality: lastQuality,
        difficultyScore: difficultyScore,
      );

  static FlashcardModel fromEntity(Flashcard card) => FlashcardModel(
        id: card.id,
        front: card.front,
        back: card.back,
        hint: card.hint,
        tags: card.tags,
        nextReviewAt: card.nextReviewAt,
        intervalDays: card.intervalDays,
        easeFactor: card.easeFactor,
        repetitions: card.repetitions,
        lapses: card.lapses,
        totalReviews: card.totalReviews,
        lastReviewAt: card.lastReviewAt,
        lastQuality: card.lastQuality,
        difficultyScore: card.difficultyScore,
      );
}
