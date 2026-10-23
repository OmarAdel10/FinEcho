import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';

/// Thrown when a budget change fails validation.
class BudgetValidationException implements Exception {
  /// Creates a validation exception with a user-facing [message].
  const new(this.message);

  /// The user-facing validation message.
  final String message;

  @override
  String toString() => message;
}

/// Validates and coordinates FinEcho budget persistence.
class BudgetService {
  /// Creates a budget service.
  const new({
    required BudgetRepository budgets,
    required CategoryRepository categories,
    String Function()? newId,
  }) : this._(budgets, categories, newId ?? _defaultNewId);

  const new _(this._budgets, this._categories, this._newId);

  final BudgetRepository _budgets;
  final CategoryRepository _categories;
  final String Function() _newId;

  /// Returns all budgets.
  Future<List<Budget>> listBudgets() => _budgets.list();

  /// Returns all categories.
  Future<List<Category>> listCategories() => _categories.list();

  /// Creates and persists a new budget.
  Future<Budget> createBudget({
    required String categoryId,
    required int allocatedAmountMinorUnits,
    required String period,
    required DateTime startDate,
    double? warningShare,
    String? currency,
  }) async {
    if (allocatedAmountMinorUnits <= 0) {
      throw const BudgetValidationException(
        'Enter an allocated amount greater than zero.',
      );
    }

    _validateWarningShare(warningShare);

    final category = await _categories.get(categoryId);
    if (category == null) {
      throw const BudgetValidationException('Choose a valid category.');
    }

    var id = _newId();
    final existing = await _budgets.list();
    var attempt = 0;
    while (existing.any((budget) => budget.id == id) && attempt < 5) {
      id = '${_newId()}-${++attempt}';
    }
    if (existing.any((budget) => budget.id == id)) {
      throw StateError('Could not generate a unique budget id.');
    }

    final budget = Budget(
      id: id,
      categoryId: categoryId,
      allocatedAmountMinorUnits: allocatedAmountMinorUnits,
      period: BudgetPeriod.values.byName(period),
      startDate: startDate,
      warningShare: warningShare,
      currency: currency,
    );
    await _budgets.create(budget);
    return budget;
  }

  /// Updates an existing [budget].
  Future<Budget> updateBudget({
    required Budget budget,
    required String categoryId,
    required int allocatedAmountMinorUnits,
    required String period,
    required DateTime startDate,
    double? warningShare,
    String? currency,
  }) async {
    if (allocatedAmountMinorUnits <= 0) {
      throw const BudgetValidationException(
        'Enter an allocated amount greater than zero.',
      );
    }

    _validateWarningShare(warningShare);

    final category = await _categories.get(categoryId);
    if (category == null) {
      throw const BudgetValidationException('Choose a valid category.');
    }

    final updated = budget.copyWith(
      categoryId: categoryId,
      allocatedAmountMinorUnits: allocatedAmountMinorUnits,
      period: BudgetPeriod.values.byName(period),
      startDate: startDate,
      warningShare: warningShare,
      currency: currency,
    );
    await _budgets.update(updated);
    return updated;
  }

  /// Deletes the budget with [id].
  Future<void> deleteBudget(String id) async {
    await _budgets.delete(id);
  }

  static void _validateWarningShare(double? warningShare) {
    if (warningShare == null) {
      return;
    }
    if (warningShare <= 0 || warningShare >= 1) {
      throw const BudgetValidationException(
        'The warning threshold must be a share between zero and one.',
      );
    }
  }

  static String _defaultNewId() {
    return 'budget-${DateTime.now().microsecondsSinceEpoch}';
  }
}
