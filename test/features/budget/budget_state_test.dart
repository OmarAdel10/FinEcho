import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/features/budget/view_model/models/budget_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes every ViewModel lifecycle status', () {
    expect(BudgetStatus.values, <BudgetStatus>[
      BudgetStatus.loading,
      BudgetStatus.ready,
      BudgetStatus.submitting,
      BudgetStatus.failure,
    ]);
  });

  test('starts with safe defaults', () {
    const state = BudgetState();

    expect(state.status, BudgetStatus.loading);
    expect(state.budgets, isEmpty);
    expect(state.categories, isEmpty);
    expect(state.errorMessage, isNull);
    expect(state.failureSource, BudgetFailureSource.load);
    expect(state.isSubmitting, isFalse);
  });

  test('reports only submission as in progress', () {
    expect(
      BudgetStatus.values.map((status) => status == BudgetStatus.submitting),
      <bool>[false, false, true, false],
    );
  });

  test('copies supplied fields without changing omitted fields', () {
    const category = Category(
      id: 'category-1',
      name: 'Food',
      iconKey: 'restaurant',
      colorHex: '#FF5722',
    );
    final budget = Budget(
      id: 'budget-1',
      categoryId: 'category-1',
      allocatedAmountMinorUnits: 10000,
      period: BudgetPeriod.monthly,
      startDate: DateTime.utc(2026, 10, 2),
    );
    final state = BudgetState(
      status: BudgetStatus.failure,
      budgets: [budget],
      categories: const [category],
      errorMessage: 'load failed',
    );

    final copied = state.copyWith(status: BudgetStatus.ready);

    expect(copied.status, BudgetStatus.ready);
    expect(copied.budgets, state.budgets);
    expect(copied.categories, state.categories);
    expect(copied.errorMessage, state.errorMessage);
    expect(copied.failureSource, state.failureSource);
  });

  test('clears and restores an error message', () {
    const state = BudgetState(errorMessage: 'load failed');

    final cleared = state.copyWith(clearErrorMessage: true);
    final restored = cleared.copyWith(errorMessage: 'save failed');

    expect(cleared.errorMessage, isNull);
    expect(restored.errorMessage, 'save failed');
  });

  test('replaces the failure source', () {
    const state = BudgetState();

    final mutated = state.copyWith(
      status: BudgetStatus.failure,
      errorMessage: 'save failed',
      failureSource: BudgetFailureSource.mutation,
    );

    expect(mutated.failureSource, BudgetFailureSource.mutation);
  });
}
