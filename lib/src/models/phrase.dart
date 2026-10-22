class Phrase {
  const Phrase({
    required this.id,
    required this.islandId,
    required this.englishText,
    required this.translation,
  });

  final int id;
  final int islandId;
  final String englishText;
  final String translation;

  factory Phrase.fromMap(Map<String, Object?> map) {
    return Phrase(
      id: map['id']! as int,
      islandId: map['island_id']! as int,
      englishText: map['english_text']! as String,
      translation: map['translation']! as String,
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
