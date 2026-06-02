/// User response when reviewing a card — mapped to SM-2 quality (0–5).
enum ReviewRating {
  /// Quality 1 — forgot, review soon.
  again,

  /// Quality 3 — recalled with difficulty.
  hard,

  /// Quality 4 — recalled correctly.
  good,

  /// Quality 5 — too easy.
  easy,
}

extension ReviewRatingSm2 on ReviewRating {
  int get sm2Quality => switch (this) {
        ReviewRating.again => 1,
        ReviewRating.hard => 3,
        ReviewRating.good => 4,
        ReviewRating.easy => 5,
      };
}
