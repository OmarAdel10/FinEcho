import 'package:finecho/core/models/budget.dart';
import 'package:finecho/features/budget/data/repositories/in_memory_budget_repository.dart';
import 'package:finecho/features/budget/view_model/services/budget_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_budget_repositories.dart';

void main() {
  group('BudgetService', () {
    test('rejects a zero allocation without writing', () async {
      final harness = BudgetTestHarness(
        initialCategories: {'category-1': testCategory()},
      );

      await expectLater(
        harness.service.createBudget(
          categoryId: 'category-1',
          allocatedAmountMinorUnits: 0,
          period: 'monthly',
          startDate: DateTime.utc(2026, 10),
        ),
        throwsA(
          isA<BudgetValidationException>().having(
            (error) => error.message,
            'message',
            'Enter an allocated amount greater than zero.',
          ),
        ),
      );
      expect(harness.budgetRepository.createdIds, isEmpty);
    });

    test('rejects a missing category without writing', () async {
      final harness = BudgetTestHarness();

      await expectLater(
        harness.service.createBudget(
          categoryId: 'missing-category',
          allocatedAmountMinorUnits: 1000,
          period: 'monthly',
          startDate: DateTime.utc(2026, 10),
        ),
        throwsA(
          isA<BudgetValidationException>().having(
            (error) => error.message,
            'message',
            'Choose a valid category.',
          ),
        ),
      );
      expect(harness.budgetRepository.createdIds, isEmpty);
    });

    test('creates a valid budget', () async {
      final harness = BudgetTestHarness(
        initialCategories: {'category-1': testCategory()},
      );

      final budget = await harness.service.createBudget(
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 1250,
        period: 'monthly',
        startDate: DateTime.utc(2026, 10),
      );

      expect(budget.id, 'budget-new');
      expect(budget.period, BudgetPeriod.monthly);
      expect(harness.budgetRepository.createdIds, <String>['budget-new']);
      expect(
        harness.budgetRepository.budgets,
        containsPair('budget-new', budget),
      );
    });

    test('updates a budget and preserves its identity', () async {
      final original = testBudget();
      final harness = BudgetTestHarness(
        initialBudgets: {original.id: original},
        initialCategories: {'category-1': testCategory()},
      );

      final updated = await harness.service.updateBudget(
        budget: original,
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 2500,
        period: 'weekly',
        startDate: DateTime.utc(2026, 11),
      );

      expect(updated.id, original.id);
      expect(updated.allocatedAmountMinorUnits, 2500);
      expect(updated.period, BudgetPeriod.weekly);
      expect(harness.budgetRepository.updatedIds, <String>[original.id]);
      expect(harness.budgetRepository.budgets[original.id], updated);
    });

    test('lists budgets and deletes a budget', () async {
      final budget = testBudget();
      final harness = BudgetTestHarness(
        initialBudgets: {budget.id: budget},
        initialCategories: {'category-1': testCategory()},
      );

      expect(await harness.service.listBudgets(), <Budget>[budget]);
      expect((await harness.service.listCategories()).single.id, 'category-1');

      await harness.service.deleteBudget(budget.id);

      expect(harness.budgetRepository.deletedIds, <String>[budget.id]);
      expect(harness.budgetRepository.budgets, isEmpty);
    });
  });

  group('InMemoryBudgetRepository', () {
    test('performs the full repository contract', () async {
      final repository = InMemoryBudgetRepository();
      final budget = testBudget(id: 'memory-budget');

      expect(await repository.get('memory-budget'), isNull);
      await repository.create(budget);
      expect(await repository.get('memory-budget'), budget);
      expect(await repository.list(), <Budget>[budget]);

      final updated = budget.copyWith(allocatedAmountMinorUnits: 5000);
      await repository.update(updated);
      expect(await repository.get('memory-budget'), updated);

      await repository.delete('memory-budget');
      expect(await repository.get('memory-budget'), isNull);
      expect(await repository.list(), isEmpty);
    });
  });
}
