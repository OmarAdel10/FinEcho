import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed budget repository implementation.
class SqfliteBudgetRepository implements BudgetRepository {
  /// Creates a repository backed by the supplied SQLite database.
  const new(this._database);

  final Database _database;

  @override
  Future<List<Budget>> list() async {
    final rows = await _database.query('budgets', orderBy: 'start_date DESC');
    return rows.map(Budget.fromMap).toList();
  }

  @override
  Future<Budget?> get(String id) async {
    final rows = await _database.query(
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
    await _database.insert('budgets', budget.toMap());
  }

  @override
  Future<void> update(Budget budget) async {
    await _database.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[budget.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await _database.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> eraseAll() async {
    await _database.delete('budgets');
  }
}
