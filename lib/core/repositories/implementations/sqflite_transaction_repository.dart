import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed transaction repository implementation.
class SqfliteTransactionRepository implements TransactionRepository {
  /// Creates a repository backed by the supplied SQLite database.
  const new(this._database);

  final Database _database;

  @override
  Future<List<Transaction>> list() async {
    final rows = await _database.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  @override
  Future<Transaction?> get(String id) async {
    final rows = await _database.query(
      'transactions',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Transaction.fromMap(rows.first);
  }

  @override
  Future<void> create(Transaction transaction) async {
    await _database.insert('transactions', transaction.toMap());
  }

  @override
  Future<void> update(Transaction transaction) async {
    await _database.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[transaction.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _database.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> eraseAll() async {
    await _database.delete('transactions');
  }
}
