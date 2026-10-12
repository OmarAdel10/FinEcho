import 'package:finecho/core/models/speech_draft.dart';
import 'package:finecho/core/repositories/contracts/speech_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed speech draft repository implementation.
class SqfliteSpeechRepository implements SpeechRepository {
  /// Creates a repository backed by the supplied SQLite database.
  const new(this._database);

  final Database _database;

  @override
  Future<List<SpeechDraft>> list() async {
    final rows = await _database.query(
      'speech_drafts',
      orderBy: 'updated_at DESC',
    );
    return rows.map(SpeechDraft.fromMap).toList();
  }

  @override
  Future<SpeechDraft?> get(String id) async {
    final rows = await _database.query(
      'speech_drafts',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return SpeechDraft.fromMap(rows.first);
  }

  @override
  Future<void> create(SpeechDraft draft) async {
    await _database.insert('speech_drafts', draft.toMap());
  }

  @override
  Future<void> update(SpeechDraft draft) async {
    await _database.update(
      'speech_drafts',
      draft.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[draft.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _database.delete(
      'speech_drafts',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
