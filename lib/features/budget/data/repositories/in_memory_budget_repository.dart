import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';

/// An in-memory [BudgetRepository] implementation for development and tests
/// until the encrypted database wiring task lands.
class InMemoryBudgetRepository implements BudgetRepository {
  /// Creates an in-memory budget repository with optional initial budgets.
  new({Map<String, Budget> initialBudgets = const <String, Budget>{}})
    : _budgets = Map.of(initialBudgets);

  final Map<String, Budget> _budgets;

  @override
  Future<List<Budget>> list() async => _budgets.values.toList();

  @override
  Future<Budget?> get(String id) async => _budgets[id];

  @override
  Future<void> create(Budget budget) async {
    _budgets[budget.id] = budget;
  }

  @override
  Future<void> update(Budget budget) async {
    _budgets[budget.id] = budget;
  }

  @override
  Future<void> delete(String id) async {
    _budgets.remove(id);
  }
}
