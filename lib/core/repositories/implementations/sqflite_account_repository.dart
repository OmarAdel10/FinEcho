import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed account repository implementation.
class SqfliteAccountRepository implements AccountRepository {
  /// Creates a repository backed by the supplied SQLite database.
  const new(this._database);

  final Database _database;

  @override
  Future<List<Account>> list() async {
    final rows = await _database.query('accounts', orderBy: 'name');
    return rows.map(Account.fromMap).toList();
  }

  @override
  Future<Account?> get(String id) async {
    final rows = await _database.query(
      'accounts',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Account.fromMap(rows.first);
  }

  @override
  Future<void> create(Account account) async {
    await _database.insert('accounts', account.toMap());
  }

  @override
  Future<void> update(Account account) async {
    await _database.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[account.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _database.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> eraseAll() async {
    await _database.delete('accounts');
  }
}
