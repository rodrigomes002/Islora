class Phrase {
  const Phrase({
    required this.id,
    required this.islandId,
    required this.englishText,
    required this.translation,
    this.reviewIntervalDays = 0,
    this.nextReviewAt,
  });

  final int id;
  final int islandId;
  final String englishText;
  final String translation;
  final int reviewIntervalDays;
  final DateTime? nextReviewAt;

  factory Phrase.fromMap(Map<String, Object?> map) {
    return Phrase(
      id: map['id']! as int,
      islandId: map['island_id']! as int,
      englishText: map['english_text']! as String,
      translation: map['translation']! as String,
      reviewIntervalDays: map['review_interval_days'] as int? ?? 0,
      nextReviewAt: map['next_review_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['next_review_at']! as int),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'island_id': islandId,
      'english_text': englishText,
      'translation': translation,
    };
  }
}
