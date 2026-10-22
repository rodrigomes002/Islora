import 'package:flutter/foundation.dart';

import '../models/island.dart';
import '../models/learning_backup.dart';
import '../models/phrase.dart';
import '../models/phrase_review_schedule.dart';
import '../repositories/learning_repository.dart';
import '../services/speech_service.dart';

class LearningViewModel extends ChangeNotifier {
  LearningViewModel({required this.repository, required this.speechService});

  final LearningRepository repository;
  final SpeechService speechService;
  final Map<int, List<Phrase>> _phrasesByIsland = {};

  List<Island> islands = const [];
  List<Phrase> duePhrases = const [];
  bool isLoading = false;
  String? errorMessage;

  List<Phrase> phrasesFor(int islandId) =>
      _phrasesByIsland[islandId] ?? const [];

  Future<void> loadIslands() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      islands = await repository.getIslands();
      duePhrases = await repository.getDuePhrases(DateTime.now());
    } on Exception catch (error) {
      errorMessage = 'Não foi possível carregar suas ilhas: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPhrases(int islandId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _phrasesByIsland[islandId] = await repository.getPhrases(islandId);
    } on Exception catch (error) {
      errorMessage = 'Não foi possível carregar as frases: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addIsland({
    required String name,
    required String description,
  }) async {
    try {
      await repository.addIsland(
        name: name.trim(),
        description: description.trim(),
      );
      islands = await repository.getIslands();
      errorMessage = null;
      notifyListeners();
      return true;
    } on Exception catch (error) {
      errorMessage = 'Não foi possível salvar a ilha: $error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addPhrase({
    required int islandId,
    required String englishText,
    required String translation,
  }) async {
    try {
      await repository.addPhrase(
        islandId: islandId,
        englishText: englishText.trim(),
        translation: translation.trim(),
      );
      _phrasesByIsland[islandId] = await repository.getPhrases(islandId);
      duePhrases = await repository.getDuePhrases(DateTime.now());
      errorMessage = null;
      notifyListeners();
      return true;
    } on Exception catch (error) {
      errorMessage = 'Não foi possível salvar a frase: $error';
      notifyListeners();
      return false;
    }
  }

  Future<void> deletePhrase({
    required int islandId,
    required int phraseId,
  }) async {
    try {
      await repository.deletePhrase(phraseId);
      _phrasesByIsland[islandId] = await repository.getPhrases(islandId);
      duePhrases = await repository.getDuePhrases(DateTime.now());
      errorMessage = null;
    } on Exception catch (error) {
      errorMessage = 'Não foi possível excluir a frase: $error';
    }
    notifyListeners();
  }

  Future<void> loadDuePhrases() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      duePhrases = await repository.getDuePhrases(DateTime.now());
    } on Exception catch (error) {
      errorMessage = 'Não foi possível carregar as frases para revisão: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportBackup() async {
    try {
      final backup = await repository.exportBackup();
      errorMessage = null;
      return backup.toJson();
    } on Exception catch (error) {
      errorMessage = 'Não foi possível exportar seus textos: $error';
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> importBackup(String source) async {
    try {
      final backup = LearningBackup.fromJson(source);
      await repository.importBackup(backup);
      islands = await repository.getIslands();
      duePhrases = await repository.getDuePhrases(DateTime.now());
      _phrasesByIsland.clear();
      errorMessage = null;
      return true;
    } on Exception catch (error) {
      errorMessage = 'Não foi possível importar o backup: $error';
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> reviewPhrase({
    required Phrase phrase,
    required bool wasCorrect,
  }) async {
    try {
      final intervalDays = PhraseReviewSchedule.nextIntervalDays(
        currentIntervalDays: phrase.reviewIntervalDays,
        wasCorrect: wasCorrect,
      );
      await repository.schedulePhraseReview(
        phraseId: phrase.id,
        intervalDays: intervalDays,
        nextReviewAt: DateTime.now().add(Duration(days: intervalDays)),
      );
      duePhrases = await repository.getDuePhrases(DateTime.now());
      errorMessage = null;
      notifyListeners();
      return true;
    } on Exception catch (error) {
      errorMessage = 'Não foi possível salvar sua revisão: $error';
      notifyListeners();
      return false;
    }
  }

  Future<void> speak(String text) async {
    try {
      await speechService.speak(text);
      errorMessage = null;
    } on Exception catch (error) {
      errorMessage = 'Não foi possível reproduzir o áudio: $error';
    }
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
