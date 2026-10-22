import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islora/main.dart';
import 'package:islora/src/models/island.dart';
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
