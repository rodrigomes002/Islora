import 'dart:convert';

import 'island.dart';
import 'phrase.dart';

class LearningBackup {
  const LearningBackup({required this.islands, required this.phrases});

  static const _formatVersion = 1;

  final List<Island> islands;
  final List<Phrase> phrases;

  factory LearningBackup.fromJson(String source) {
    final decoded = jsonDecode(source);
    final root = _readMap(decoded, 'backup');

    if (root['format_version'] != _formatVersion) {
      throw const FormatException('Versão de backup não suportada.');
    }

    final islands = _readList(root['islands'], 'ilhas')
        .map((value) {
          final map = _readMap(value, 'ilha');
          final id = _readInt(map['id'], 'id da ilha');
          final name = _readString(map['name'], 'nome da ilha');
          final description = _readString(
            map['description'],
            'descrição da ilha',
          );
          return Island(id: id, name: name, description: description);
        })
        .toList(growable: false);
    final islandIds = islands.map((island) => island.id).toSet();
    if (islandIds.length != islands.length || islandIds.any((id) => id <= 0)) {
      throw const FormatException('O backup contém IDs de ilha inválidos.');
    }

    final phrases = _readList(root['phrases'], 'frases')
        .map((value) {
          final map = _readMap(value, 'frase');
          final id = _readInt(map['id'], 'id da frase');
          final islandId = _readInt(map['island_id'], 'ilha da frase');
          final englishText = _readString(map['english_text'], 'texto em inglês');
          final translation = _readString(map['translation'], 'tradução');
          final reviewIntervalDays = _readInt(
            map['review_interval_days'],
            'intervalo de revisão',
          );
          final nextReviewAt = map['next_review_at'];
          if (nextReviewAt != null && nextReviewAt is! int) {
            throw const FormatException('Data de revisão inválida.');
          }
          if (id <= 0 ||
              !islandIds.contains(islandId) ||
              reviewIntervalDays < 0) {
            throw const FormatException('O backup contém uma frase inválida.');
          }
          return Phrase(
            id: id,
            islandId: islandId,
            englishText: englishText,
            translation: translation,
            reviewIntervalDays: reviewIntervalDays,
            nextReviewAt: nextReviewAt == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    _readInt(nextReviewAt, 'data de revisão'),
                  ),
          );
        })
        .toList(growable: false);

    final phraseIds = phrases.map((phrase) => phrase.id).toSet();
    if (phraseIds.length != phrases.length) {
      throw const FormatException('O backup contém IDs de frase duplicados.');
    }

    return LearningBackup(islands: islands, phrases: phrases);
  }

  String toJson() {
    return jsonEncode({
      'format_version': _formatVersion,
      'islands': islands
          .map(
            (island) => {
              'id': island.id,
              'name': island.name,
              'description': island.description,
            },
          )
          .toList(growable: false),
      'phrases': phrases
          .map(
            (phrase) => {
              'id': phrase.id,
              'island_id': phrase.islandId,
              'english_text': phrase.englishText,
              'translation': phrase.translation,
              'review_interval_days': phrase.reviewIntervalDays,
              'next_review_at': phrase.nextReviewAt?.millisecondsSinceEpoch,
            },
          )
          .toList(growable: false),
    });
  }

  static Map<String, Object?> _readMap(Object? value, String field) {
    if (value is! Map) {
      throw FormatException('Campo inválido no backup: $field.');
    }
    final map = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw FormatException('Campo inválido no backup: $field.');
      }
      map[entry.key as String] = entry.value;
    }
    return map;
  }

  static List<Object?> _readList(Object? value, String field) {
    if (value is! List) {
      throw FormatException('Lista inválida no backup: $field.');
    }
    return value;
  }

  static int _readInt(Object? value, String field) {
    if (value is! int) {
      throw FormatException('Campo inválido no backup: $field.');
    }
    return value;
  }

  static String _readString(Object? value, String field) {
    if (value is! String) {
      throw FormatException('Campo inválido no backup: $field.');
    }
    return value;
  }
}
