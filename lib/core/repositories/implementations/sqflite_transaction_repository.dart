import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// SQLCipher-backed [TransactionRepository].
class SqfliteTransactionRepository implements TransactionRepository {
  /// Creates a repository that opens the encrypted database for each call.
  const new({required this.opener});

  /// Opens the encrypted database that stores the transactions.
  final Future<Database> Function() opener;

  @override
  Future<List<Transaction>> list() async {
    final database = await opener();
    final rows = await database.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  @override
  Future<Transaction?> get(String id) async {
    final database = await opener();
    final rows = await database.query(
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
    final database = await opener();
    await database.insert('transactions', transaction.toMap());
  }

  @override
  Future<void> update(Transaction transaction) async {
    final database = await opener();
    await database.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[transaction.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final database = await opener();
    await database.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> eraseAll() async {
    final database = await opener();
    await database.delete('transactions');
  }
}
