import 'dart:async';

import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/features/budget/view_model/services/budget_service.dart';

/// An in-memory [BudgetRepository] fake for budget tests.
class FakeBudgetRepository implements BudgetRepository {
  /// Creates a fake budget repository with optional initial budgets.
  new({Map<String, Budget> initialBudgets = const <String, Budget>{}})
    : _budgets = Map<String, Budget>.of(initialBudgets);

  final Map<String, Budget> _budgets;

  /// Every id passed to [create], in persistence order.
  final List<String> createdIds = <String>[];

  /// Every id passed to [update], in persistence order.
  final List<String> updatedIds = <String>[];

  /// Every id passed to [delete], in persistence order.
  final List<String> deletedIds = <String>[];

  /// Errors to throw from [list].
  Exception? listError;

  /// Errors to throw from [create].
  Exception? createError;

  /// Errors to throw from [update].
  Exception? updateError;

  /// Errors to throw from [delete].
  Exception? deleteError;

  /// An optional gate that keeps the next [create] call pending.
  Completer<void>? createGate;

  /// An optional gate that keeps the next [update] call pending.
  Completer<void>? updateGate;

  /// An optional gate that keeps the next [list] call pending.
  Completer<void>? listGate;

  /// The current budgets, keyed by id.
  Map<String, Budget> get budgets => Map.unmodifiable(_budgets);

  @override
  Future<List<Budget>> list() async {
    final error = listError;
    if (error != null) {
      throw error;
    }
    final gate = listGate;
    if (gate != null) {
      await gate.future;
    }
    return _budgets.values.toList();
  }

  @override
  Future<Budget?> get(String id) async => _budgets[id];

  @override
  Future<void> create(Budget budget) async {
    final gate = createGate;
    if (gate != null) {
      await gate.future;
    }
    final error = createError;
    if (error != null) {
      throw error;
    }
    createdIds.add(budget.id);
    _budgets[budget.id] = budget;
  }

  @override
  Future<void> update(Budget budget) async {
    final gate = updateGate;
    if (gate != null) {
      await gate.future;
    }
    final error = updateError;
    if (error != null) {
      throw error;
    }
    updatedIds.add(budget.id);
    _budgets[budget.id] = budget;
  }

  @override
  Future<void> delete(String id) async {
    final error = deleteError;
    if (error != null) {
      throw error;
    }
    deletedIds.add(id);
    _budgets.remove(id);
  }

  @override
  Future<void> eraseAll() async {
    _budgets.clear();
  }
}

/// An in-memory [CategoryRepository] fake for budget tests.
class FakeBudgetCategoryRepository implements CategoryRepository {
  /// Creates a fake category repository with optional initial categories.
  new({Map<String, Category> initialCategories = const <String, Category>{}})
    : _categories = Map<String, Category>.of(initialCategories);

  final Map<String, Category> _categories;

  /// Errors to throw from [list].
  Exception? listError;

  /// The current categories, keyed by id.
  Map<String, Category> get categories => Map.unmodifiable(_categories);

  @override
  Future<List<Category>> list() async {
    final error = listError;
    if (error != null) {
      throw error;
    }
    return _categories.values.toList();
  }

  @override
  Future<Category?> get(String id) async => _categories[id];

  @override
  Future<void> create(Category category) async {
    _categories[category.id] = category;
  }

  @override
  Future<void> update(Category category) async {
    _categories[category.id] = category;
  }

  @override
  Future<void> delete(String id) async {
    _categories.remove(id);
  }

  @override
  Future<void> eraseAll() async {
    _categories.clear();
  }
}

/// A bundle of budget fakes and the service built from them.
class BudgetTestHarness {
  /// Creates the fake repository bundle and its deterministic service.
  new({
    Map<String, Budget> initialBudgets = const <String, Budget>{},
    Map<String, Category> initialCategories = const <String, Category>{},
    String Function()? newId,
  }) : budgetRepository = FakeBudgetRepository(initialBudgets: initialBudgets),
       categoryRepository = FakeBudgetCategoryRepository(
         initialCategories: initialCategories,
       ) {
    service = BudgetService(
      budgets: budgetRepository,
      categories: categoryRepository,
      newId: newId ?? () => 'budget-new',
    );
  }

  /// The fake budget store.
  final FakeBudgetRepository budgetRepository;

  /// The fake category store.
  final FakeBudgetCategoryRepository categoryRepository;

  /// The service under test, backed by the fakes.
  late final BudgetService service;
}

/// Builds the category used by most budget tests.
Category testCategory() {
  return const Category(
    id: 'category-1',
    name: 'Food',
    iconKey: 'restaurant',
    colorHex: '#FF5722',
  );
}

/// Builds a budget for the category used by most budget tests.
Budget testBudget({
  String id = 'budget-1',
  String categoryId = 'category-1',
  int allocatedAmountMinorUnits = 10000,
  BudgetPeriod period = BudgetPeriod.monthly,
  DateTime? startDate,
  double? warningShare,
}) {
  return Budget(
    id: id,
    categoryId: categoryId,
    allocatedAmountMinorUnits: allocatedAmountMinorUnits,
    period: period,
    startDate: startDate ?? DateTime.utc(2026, 10),
    warningShare: warningShare,
  );
}
