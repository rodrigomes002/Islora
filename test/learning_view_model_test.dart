import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islora/main.dart';
import 'package:islora/src/models/island.dart';
import 'package:islora/src/models/learning_backup.dart';
import 'package:islora/src/models/phrase.dart';
import 'package:islora/src/models/phrase_review_schedule.dart';
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

  test('loads due phrases and schedules a correct answer', () async {
    await viewModel.addIsland(name: 'Travel', description: '');
    final islandId = viewModel.islands.single.id;
    await viewModel.addPhrase(
      islandId: islandId,
      englishText: 'Where is the station?',
      translation: 'Onde fica a estação?',
    );
    await viewModel.loadDuePhrases();
    final phrase = viewModel.duePhrases.single;

    final saved = await viewModel.reviewPhrase(
      phrase: phrase,
      wasCorrect: true,
    );

    expect(saved, isTrue);
    expect(viewModel.duePhrases, isEmpty);
    expect(repository.reviewIntervalFor(phrase.id), 1);
    expect(repository.nextReviewFor(phrase.id), isNotNull);
  });

  test('wrong answers restart the review interval at one day', () {
    expect(
      PhraseReviewSchedule.nextIntervalDays(
        currentIntervalDays: 14,
        wasCorrect: false,
      ),
      1,
    );
  });

  test('correct answers progress through spaced intervals', () {
    expect(
      PhraseReviewSchedule.nextIntervalDays(
        currentIntervalDays: 0,
        wasCorrect: true,
      ),
      1,
    );
    expect(
      PhraseReviewSchedule.nextIntervalDays(
        currentIntervalDays: 1,
        wasCorrect: true,
      ),
      3,
    );
    expect(
      PhraseReviewSchedule.nextIntervalDays(
        currentIntervalDays: 3,
        wasCorrect: true,
      ),
      7,
    );
    expect(
      PhraseReviewSchedule.nextIntervalDays(
        currentIntervalDays: 7,
        wasCorrect: true,
      ),
      14,
    );
    expect(
      PhraseReviewSchedule.nextIntervalDays(
        currentIntervalDays: 14,
        wasCorrect: true,
      ),
      30,
    );
  });

  test('exports text and review progress as a JSON backup', () async {
    await viewModel.addIsland(name: 'Travel', description: 'Airport phrases');
    final islandId = viewModel.islands.single.id;
    await viewModel.addPhrase(
      islandId: islandId,
      englishText: 'Where is the station?',
      translation: 'Onde fica a estação?',
    );
    final phrase = (await repository.getPhrases(islandId)).single;
    await repository.schedulePhraseReview(
      phraseId: phrase.id,
      intervalDays: 3,
      nextReviewAt: DateTime.utc(2026, 10, 25),
    );

    final json = await viewModel.exportBackup();
    final backup = LearningBackup.fromJson(json!);

    expect(backup.islands.single.description, 'Airport phrases');
    expect(backup.phrases.single.englishText, 'Where is the station?');
    expect(backup.phrases.single.reviewIntervalDays, 3);
    expect(
      backup.phrases.single.nextReviewAt?.millisecondsSinceEpoch,
      DateTime.utc(2026, 10, 25).millisecondsSinceEpoch,
    );
  });

  test('imports a backup and replaces existing data', () async {
    await viewModel.addIsland(name: 'Old island', description: '');
    final backup = LearningBackup(
      islands: const [Island(id: 10, name: 'Travel', description: 'Airport')],
      phrases: const [
        Phrase(
          id: 20,
          islandId: 10,
          englishText: 'Where is the station?',
          translation: 'Onde fica a estação?',
          reviewIntervalDays: 7,
        ),
      ],
    );

    final imported = await viewModel.importBackup(backup.toJson());

    expect(imported, isTrue);
    expect(viewModel.islands.map((island) => island.name), ['Travel']);
    expect(viewModel.duePhrases.single.reviewIntervalDays, 7);
  });

  test('rejects an invalid backup without changing existing data', () async {
    await viewModel.addIsland(name: 'Keep this', description: '');

    final imported = await viewModel.importBackup('not json');

    expect(imported, isFalse);
    expect(viewModel.islands.single.name, 'Keep this');
    expect(viewModel.errorMessage, contains('Não foi possível importar'));
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

  testWidgets('reviews a phrase by revealing and grading its translation', (
    tester,
  ) async {
    final appViewModel = LearningViewModel(
      repository: repository,
      speechService: _FakeSpeechService(),
    );
    addTearDown(appViewModel.dispose);
    await appViewModel.addIsland(name: 'Travel', description: '');
    await appViewModel.addPhrase(
      islandId: appViewModel.islands.single.id,
      englishText: 'Where is the station?',
      translation: 'Onde fica a estação?',
    );

    await tester.pumpWidget(IsloraApp(viewModel: appViewModel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar'));
    await tester.pumpAndSettle();

    expect(find.text('Where is the station?'), findsOneWidget);
    expect(find.text('Onde fica a estação?'), findsNothing);
    await tester.tap(find.text('Revelar tradução'));
    await tester.pumpAndSettle();
    expect(find.text('Onde fica a estação?'), findsOneWidget);

    await tester.tap(find.text('Acertei'));
    await tester.pumpAndSettle();
    expect(find.text('Revisão concluída!'), findsOneWidget);
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

  @override
  Future<List<Phrase>> getDuePhrases(DateTime now) async {
    return _phrasesByIsland.values
        .expand((phrases) => phrases)
        .where(
          (phrase) =>
              phrase.nextReviewAt == null || !phrase.nextReviewAt!.isAfter(now),
        )
        .toList();
  }

  @override
  Future<void> schedulePhraseReview({
    required int phraseId,
    required int intervalDays,
    required DateTime nextReviewAt,
  }) async {
    for (final phrases in _phrasesByIsland.values) {
      final index = phrases.indexWhere((phrase) => phrase.id == phraseId);
      if (index != -1) {
        final phrase = phrases[index];
        phrases[index] = Phrase(
          id: phrase.id,
          islandId: phrase.islandId,
          englishText: phrase.englishText,
          translation: phrase.translation,
          reviewIntervalDays: intervalDays,
          nextReviewAt: nextReviewAt,
        );
        return;
      }
    }
  }

  @override
  Future<LearningBackup> exportBackup() async {
    return LearningBackup(
      islands: List.of(_islands),
      phrases: _phrasesByIsland.values.expand((phrases) => phrases).toList(),
    );
  }

  @override
  Future<void> importBackup(LearningBackup backup) async {
    _islands
      ..clear()
      ..addAll(backup.islands);
    _phrasesByIsland
      ..clear()
      ..addEntries(
        backup.islands.map(
          (island) => MapEntry(
            island.id,
            backup.phrases
                .where((phrase) => phrase.islandId == island.id)
                .toList(),
          ),
        ),
      );
    _nextIslandId = backup.islands.isEmpty
        ? 1
        : backup.islands
                  .map((island) => island.id)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    _nextPhraseId = backup.phrases.isEmpty
        ? 1
        : backup.phrases
                  .map((phrase) => phrase.id)
                  .reduce((a, b) => a > b ? a : b) +
              1;
  }

  int? reviewIntervalFor(int phraseId) {
    return _phrasesByIsland.values
        .expand((phrases) => phrases)
        .firstWhere((phrase) => phrase.id == phraseId)
        .reviewIntervalDays;
  }

  DateTime? nextReviewFor(int phraseId) {
    return _phrasesByIsland.values
        .expand((phrases) => phrases)
        .firstWhere((phrase) => phrase.id == phraseId)
        .nextReviewAt;
  }
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
