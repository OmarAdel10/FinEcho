import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart'
    show ConflictAlgorithm, Database;

/// A SQLCipher-backed security repository implementation.
class SqfliteSecurityRepository implements SecurityRepository {
  /// Creates a repository backed by the supplied SQLite database.
  const new(this._database);

  final Database _database;

  @override
  Future<SecurityState?> get() async {
    final rows = await _database.query(
      'security_state',
      where: 'id = ?',
      whereArgs: <Object?>[SecurityState.singletonId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return SecurityState.fromMap(rows.first);
  }

  @override
  Future<void> update(SecurityState state) async {
    await _database.insert(
      'security_state',
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
