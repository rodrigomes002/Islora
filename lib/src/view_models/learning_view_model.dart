import 'package:flutter/foundation.dart';

import '../models/island.dart';
import '../models/phrase.dart';
import '../repositories/learning_repository.dart';
import '../services/speech_service.dart';

class LearningViewModel extends ChangeNotifier {
  LearningViewModel({required this.repository, required this.speechService});

  final LearningRepository repository;
  final SpeechService speechService;
  final Map<int, List<Phrase>> _phrasesByIsland = {};

  List<Island> islands = const [];
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
      errorMessage = null;
    } on Exception catch (error) {
      errorMessage = 'Não foi possível excluir a frase: $error';
    }
    notifyListeners();
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
