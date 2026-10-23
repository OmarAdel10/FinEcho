import 'package:finecho/core/models/budget.dart';

/// Persists and reads FinEcho budgets.
abstract interface class BudgetRepository {
  /// Returns all budgets.
  Future<List<Budget>> list();

  /// Returns the budget with [id], or `null` when it does not exist.
  Future<Budget?> get(String id);

  /// Inserts [budget].
  Future<void> create(Budget budget);

  /// Replaces the stored budget with the same id as [budget].
  Future<void> update(Budget budget);

  /// Deletes the budget with [id].
  Future<void> delete(String id);

  /// Erases all budgets.
  Future<void> eraseAll();
}
