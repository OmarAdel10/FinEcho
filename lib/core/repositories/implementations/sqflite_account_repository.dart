import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed account repository implementation.
class SqfliteAccountRepository implements AccountRepository {
  /// Creates a repository that opens the encrypted database that stores the
  /// accounts for every call.
  const new({required this.opener});

  /// Opens the encrypted database that stores the accounts.
  final Future<Database> Function() opener;

  @override
  Future<List<Account>> list() async {
    final database = await opener();
    final rows = await database.query('accounts', orderBy: 'name');
    return rows.map(Account.fromMap).toList();
  }

  @override
  Future<Account?> get(String id) async {
    final database = await opener();
    final rows = await database.query(
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
    final database = await opener();
    await database.insert('accounts', account.toMap());
  }

  @override
  Future<void> update(Account account) async {
    final database = await opener();
    await database.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[account.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final database = await opener();
    await database.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> eraseAll() async {
    final database = await opener();
    await database.delete('accounts');
  }
}
