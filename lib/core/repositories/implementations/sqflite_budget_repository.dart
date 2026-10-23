import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed budget repository implementation.
class SqfliteBudgetRepository implements BudgetRepository {
  /// Creates a repository that opens the encrypted database on demand.
  const new({required this.opener});

  /// Opens the encrypted database when a query runs.
  ///
  /// The database is opened lazily so nothing touches secure storage or the
  /// file system before the first query.
  final Future<Database> Function() opener;

  @override
  Future<List<Budget>> list() async {
    final database = await opener();
    final rows = await database.query('budgets', orderBy: 'start_date DESC');
    return rows.map(Budget.fromMap).toList();
  }

  @override
  Future<Budget?> get(String id) async {
    final database = await opener();
    final rows = await database.query(
      'budgets',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Budget.fromMap(rows.first);
  }

  @override
  Future<void> create(Budget budget) async {
    final database = await opener();
    await database.insert('budgets', budget.toMap());
  }

  @override
  Future<void> update(Budget budget) async {
    final database = await opener();
    await database.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[budget.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    final database = await opener();
    await database.delete('budgets', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  @override
  Future<void> eraseAll() async {
    final database = await opener();
    await database.delete('budgets');
  }
}
