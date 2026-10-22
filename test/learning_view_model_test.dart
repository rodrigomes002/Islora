import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islora/main.dart';
import 'package:islora/src/models/island.dart';
import 'package:islora/src/models/phrase.dart';
import 'package:islora/src/repositories/learning_repository.dart';
import 'package:islora/src/services/speech_service.dart';
import 'package:islora/src/view_models/learning_view_model.dart';

void main() {
  late _FakeLearningRepository repository;
  late LearningViewModel viewModel;

  setUp(() {
    repository = _FakeLearningRepository();
    viewModel = LearningViewModel(
      repository: repository,
      speechService: _FakeSpeechService(),
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('creates an island and stores a trimmed name', () async {
    final created = await viewModel.addIsland(
      name: '  Travel  ',
      description: '  At the airport  ',
    );

    expect(created, isTrue);
    expect(viewModel.islands.single.name, 'Travel');
    expect(viewModel.islands.single.description, 'At the airport');
  });

  test('adds phrase to the selected island and reloads its list', () async {
    await viewModel.addIsland(name: 'Travel', description: '');
    final islandId = viewModel.islands.single.id;
    await viewModel.loadPhrases(islandId);

    final created = await viewModel.addPhrase(
      islandId: islandId,
      englishText: '  Where is the station? ',
      translation: '  Onde fica a estação? ',
    );

    expect(created, isTrue);
    expect(
      viewModel.phrasesFor(islandId).single.englishText,
      'Where is the station?',
    );
    expect(
      viewModel.phrasesFor(islandId).single.translation,
      'Onde fica a estação?',
    );
  });

  testWidgets('creates an island and phrase, then plays its audio', (
    tester,
  ) async {
    final speechService = _FakeSpeechService();
    final appViewModel = LearningViewModel(
      repository: repository,
      speechService: speechService,
    );
    addTearDown(appViewModel.dispose);

    await tester.pumpWidget(IsloraApp(viewModel: appViewModel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova ilha'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Travel');
    await tester.tap(find.text('Criar ilha'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Travel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova frase'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Where is the station?',
    );
    await tester.tap(find.text('Salvar frase'));
    await tester.pumpAndSettle();

    expect(find.text('Where is the station?'), findsOneWidget);
    await tester.tap(find.byTooltip('Ouvir frase'));
    await tester.pumpAndSettle();
    expect(speechService.lastSpoken, 'Where is the station?');
  });
}

class _FakeLearningRepository implements LearningRepository {
  final List<Island> _islands = [];
  final Map<int, List<Phrase>> _phrasesByIsland = {};
  int _nextIslandId = 1;
  int _nextPhraseId = 1;

  @override
  Future<int> addIsland({
    required String name,
    required String description,
  }) async {
    final id = _nextIslandId++;
    _islands.add(Island(id: id, name: name, description: description));
    _phrasesByIsland[id] = [];
    return id;
  }

  @override
  Future<int> addPhrase({
    required int islandId,
    required String englishText,
    required String translation,
  }) async {
    final id = _nextPhraseId++;
    _phrasesByIsland[islandId]!.add(
      Phrase(
        id: id,
        islandId: islandId,
        englishText: englishText,
        translation: translation,
      ),
    );
    return id;
  }

  @override
  Future<void> deletePhrase(int phraseId) async {
    for (final phrases in _phrasesByIsland.values) {
      phrases.removeWhere((phrase) => phrase.id == phraseId);
    }
  }

  @override
  Future<List<Island>> getIslands() async => List.of(_islands);

  @override
  Future<List<Phrase>> getPhrases(int islandId) async =>
      List.of(_phrasesByIsland[islandId]!);
}

class _FakeSpeechService implements SpeechService {
  String? lastSpoken;

  @override
  Future<void> speak(String text) async {
    lastSpoken = text;
  }

  @override
  Future<void> stop() async {}
}
