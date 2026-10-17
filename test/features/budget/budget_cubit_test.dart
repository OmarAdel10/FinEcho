import 'dart:async';

import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/budget/view_model/models/budget_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_budget_repositories.dart';

BudgetTestHarness _harness({String Function()? newId}) {
  return BudgetTestHarness(
    initialBudgets: {'budget-1': testBudget()},
    initialCategories: {'category-1': testCategory()},
    newId: newId ?? () => 'budget-new',
  );
}

void main() {
  late BudgetTestHarness harness;
  late BudgetCubit cubit;

  setUp(() {
    harness = _harness();
    cubit = BudgetCubit(harness.service);
  });

  tearDown(() => cubit.close());

  group('BudgetCubit', () {
    test('loads budgets and categories', () async {
      await cubit.load();

      expect(cubit.state.status, BudgetStatus.ready);
      expect(cubit.state.budgets.single.id, 'budget-1');
      expect(cubit.state.categories.single.id, 'category-1');
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('reports a load failure', () async {
      harness.budgetRepository.listError = Exception('load failed');

      await cubit.load();

      expect(cubit.state.status, BudgetStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Could not load budgets. Please try again.',
      );
    });

    test('creates a budget and refreshes ready state', () async {
      await cubit.load();
      final saved = await cubit.createBudget(
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 1250,
        period: 'monthly',
        startDate: DateTime.utc(2026, 10),
      );

      expect(saved, isTrue);
      expect(cubit.state.status, BudgetStatus.ready);
      expect(
        cubit.state.budgets.map((budget) => budget.id),
        contains('budget-new'),
      );
      expect(harness.budgetRepository.createdIds, <String>['budget-new']);
    });

    test('surfaces a create validation failure', () async {
      await cubit.load();
      final saved = await cubit.createBudget(
        categoryId: 'missing-category',
        allocatedAmountMinorUnits: 1250,
        period: 'monthly',
        startDate: DateTime.utc(2026, 10),
      );

      expect(saved, isFalse);
      expect(cubit.state.status, BudgetStatus.failure);
      expect(cubit.state.errorMessage, 'Choose a valid category.');
      expect(harness.budgetRepository.createdIds, isEmpty);
    });

    test('reports a create repository failure', () async {
      await cubit.load();
      harness.budgetRepository.createError = Exception('create failed');
      final saved = await cubit.createBudget(
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 1250,
        period: 'monthly',
        startDate: DateTime.utc(2026, 10),
      );

      expect(saved, isFalse);
      expect(cubit.state.status, BudgetStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Could not save the budget. Please try again.',
      );
    });

    test('updates a budget and refreshes ready state', () async {
      final original = cubit.state.budgets.isEmpty
          ? testBudget()
          : testBudget();
      harness = BudgetTestHarness(
        initialBudgets: {original.id: original},
        initialCategories: {'category-1': testCategory()},
      );
      final freshCubit = BudgetCubit(harness.service);
      await freshCubit.load();

      final saved = await freshCubit.updateBudget(
        original: original,
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 2500,
        period: 'weekly',
        startDate: DateTime.utc(2026, 11),
      );

      expect(saved, isTrue);
      expect(freshCubit.state.status, BudgetStatus.ready);
      expect(freshCubit.state.budgets.single.allocatedAmountMinorUnits, 2500);
      expect(harness.budgetRepository.updatedIds, <String>[original.id]);
      await freshCubit.close();
    });

    test('surfaces an update repository failure', () async {
      final original = testBudget();
      harness = BudgetTestHarness(
        initialBudgets: {original.id: original},
        initialCategories: {'category-1': testCategory()},
      );
      final freshCubit = BudgetCubit(harness.service);
      await freshCubit.load();
      harness.budgetRepository.updateError = Exception('update failed');

      final saved = await freshCubit.updateBudget(
        original: original,
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 2500,
        period: 'weekly',
        startDate: DateTime.utc(2026, 11),
      );

      expect(saved, isFalse);
      expect(freshCubit.state.status, BudgetStatus.failure);
      expect(
        freshCubit.state.errorMessage,
        'Could not save the budget. Please try again.',
      );
      await freshCubit.close();
    });

    test('deletes a budget and refreshes ready state', () async {
      await cubit.load();
      final deleted = await cubit.deleteBudget('budget-1');

      expect(deleted, isTrue);
      expect(cubit.state.status, BudgetStatus.ready);
      expect(cubit.state.budgets, isEmpty);
      expect(harness.budgetRepository.deletedIds, <String>['budget-1']);
    });

    test('reports a delete repository failure', () async {
      await cubit.load();
      harness.budgetRepository.deleteError = Exception('delete failed');

      final deleted = await cubit.deleteBudget('budget-1');

      expect(deleted, isFalse);
      expect(cubit.state.status, BudgetStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Could not delete the budget. Please try again.',
      );
    });

    test('ignores a mutation while another is submitting', () async {
      await cubit.load();
      harness.budgetRepository.createGate = Completer<void>();
      final first = cubit.createBudget(
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 1250,
        period: 'monthly',
        startDate: DateTime.utc(2026, 10),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isSubmitting, isTrue);
      final second = await cubit.createBudget(
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 2500,
        period: 'weekly',
        startDate: DateTime.utc(2026, 10),
      );

      expect(second, isFalse);
      expect(harness.budgetRepository.createdIds, isEmpty);
      harness.budgetRepository.createGate!.complete();
      expect(await first, isTrue);
      expect(harness.budgetRepository.createdIds, <String>['budget-new']);
    });
  });
}
