import 'package:equatable/equatable.dart';

/// Single study card (front = question, back = answer).
class Flashcard extends Equatable {
  const Flashcard({
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
  /// 0 = khó nhất, 100 = dễ nhất.
  final int difficultyScore;

  bool get isDue {
    if (nextReviewAt == null) return true;
    return !nextReviewAt!.isAfter(DateTime.now());
  }

  bool get isOverdue {
    if (nextReviewAt == null) return true;
    return nextReviewAt!.isBefore(DateTime.now());
  }

  Flashcard copyWith({
    String? front,
    String? back,
    String? hint,
    List<String>? tags,
    DateTime? nextReviewAt,
    int? intervalDays,
    double? easeFactor,
    int? repetitions,
    int? lapses,
    int? totalReviews,
    DateTime? lastReviewAt,
    int? lastQuality,
    int? difficultyScore,
    bool clearLastReview = false,
  }) {
    return Flashcard(
      id: id,
      front: front ?? this.front,
      back: back ?? this.back,
      hint: hint ?? this.hint,
      tags: tags ?? this.tags,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      totalReviews: totalReviews ?? this.totalReviews,
      lastReviewAt: clearLastReview ? null : (lastReviewAt ?? this.lastReviewAt),
      lastQuality: lastQuality ?? this.lastQuality,
      difficultyScore: difficultyScore ?? this.difficultyScore,
    );
  }

  @override
  List<Object?> get props => [
        id,
        front,
        back,
        hint,
        tags,
        nextReviewAt,
        intervalDays,
        easeFactor,
        repetitions,
        lapses,
        totalReviews,
        lastReviewAt,
        lastQuality,
        difficultyScore,
      ];
}
