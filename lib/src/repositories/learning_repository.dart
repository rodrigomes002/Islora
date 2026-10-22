import '../models/island.dart';
import '../models/phrase.dart';

abstract interface class LearningRepository {
  Future<List<Island>> getIslands();

  Future<int> addIsland({required String name, required String description});

  Future<List<Phrase>> getPhrases(int islandId);

  Future<List<Phrase>> getDuePhrases(DateTime now);

  Future<int> addPhrase({
    required int islandId,
    required String englishText,
    required String translation,
  });

  Future<void> deletePhrase(int phraseId);

  Future<void> schedulePhraseReview({
    required int phraseId,
    required int intervalDays,
    required DateTime nextReviewAt,
  });
}
