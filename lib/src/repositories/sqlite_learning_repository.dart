import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/island.dart';
import '../models/phrase.dart';
import 'learning_repository.dart';

class SqliteLearningRepository implements LearningRepository {
  Future<Database>? _database;

  Future<Database> get _db => _database ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();

    return openDatabase(
      join(databasePath, 'islora.db'),
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE islands (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE phrases (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            island_id INTEGER NOT NULL,
            english_text TEXT NOT NULL,
            translation TEXT NOT NULL,
            FOREIGN KEY (island_id) REFERENCES islands (id) ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          ALTER TABLE phrases
          ADD COLUMN review_interval_days INTEGER NOT NULL DEFAULT 0
        ''');
        await database.execute('''
          ALTER TABLE phrases
          ADD COLUMN next_review_at INTEGER
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            ALTER TABLE phrases
            ADD COLUMN review_interval_days INTEGER NOT NULL DEFAULT 0
          ''');
          await database.execute('''
            ALTER TABLE phrases
            ADD COLUMN next_review_at INTEGER
          ''');
        }
      },
    );
  }

  @override
  Future<List<Island>> getIslands() async {
    final rows = await (await _db).query('islands', orderBy: 'id DESC');
    return rows.map(Island.fromMap).toList(growable: false);
  }

  @override
  Future<int> addIsland({
    required String name,
    required String description,
  }) async {
    return (await _db).insert('islands', {
      'name': name,
      'description': description,
    });
  }

  @override
  Future<List<Phrase>> getPhrases(int islandId) async {
    final rows = await (await _db).query(
      'phrases',
      where: 'island_id = ?',
      whereArgs: [islandId],
      orderBy: 'id DESC',
    );
    return rows.map(Phrase.fromMap).toList(growable: false);
  }

  @override
  Future<List<Phrase>> getDuePhrases(DateTime now) async {
    final rows = await (await _db).query(
      'phrases',
      where: 'next_review_at IS NULL OR next_review_at <= ?',
      whereArgs: [now.millisecondsSinceEpoch],
      orderBy: 'id ASC',
    );
    return rows.map(Phrase.fromMap).toList(growable: false);
  }

  @override
  Future<int> addPhrase({
    required int islandId,
    required String englishText,
    required String translation,
  }) async {
    return (await _db).insert('phrases', {
      'island_id': islandId,
      'english_text': englishText,
      'translation': translation,
    });
  }

  @override
  Future<void> deletePhrase(int phraseId) async {
    await (await _db).delete('phrases', where: 'id = ?', whereArgs: [phraseId]);
  }

  @override
  Future<void> schedulePhraseReview({
    required int phraseId,
    required int intervalDays,
    required DateTime nextReviewAt,
  }) async {
    await (await _db).update(
      'phrases',
      {
        'review_interval_days': intervalDays,
        'next_review_at': nextReviewAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [phraseId],
    );
  }
}
