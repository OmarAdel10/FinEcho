import 'package:finecho/core/models/budget.dart';
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
      expect(budget.warningShare, isNull);
      expect(harness.budgetRepository.createdIds, <String>['budget-new']);
      expect(
        harness.budgetRepository.budgets,
        containsPair('budget-new', budget),
      );
    });

    test('creates a budget with a configured warning share', () async {
      final harness = BudgetTestHarness(
        initialCategories: {'category-1': testCategory()},
      );

      final budget = await harness.service.createBudget(
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 1250,
        period: 'monthly',
        startDate: DateTime.utc(2026, 10),
        warningShare: 0.9,
      );

      expect(budget.warningShare, 0.9);
      expect(harness.budgetRepository.budgets['budget-new']!.warningShare, 0.9);
    });

    test(
      'rejects warning shares outside the valid range without writing',
      () async {
        final harness = BudgetTestHarness(
          initialCategories: {'category-1': testCategory()},
        );

        for (final share in <double>[0, -0.5, 1, 1.5]) {
          await expectLater(
            harness.service.createBudget(
              categoryId: 'category-1',
              allocatedAmountMinorUnits: 1250,
              period: 'monthly',
              startDate: DateTime.utc(2026, 10),
              warningShare: share,
            ),
            throwsA(
              isA<BudgetValidationException>().having(
                (error) => error.message,
                'message',
                'The warning threshold must be a share between zero and one.',
              ),
            ),
          );
        }
        expect(harness.budgetRepository.createdIds, isEmpty);
      },
    );

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

    test('updates the warning share of an existing budget', () async {
      final original = testBudget().copyWith(warningShare: 0.9);
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
        warningShare: 0.7,
      );

      expect(updated.warningShare, 0.7);
      expect(harness.budgetRepository.budgets[original.id]!.warningShare, 0.7);
    });

    test('clears the warning share when the update omits it', () async {
      final original = testBudget().copyWith(warningShare: 0.9);
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

      expect(updated.warningShare, isNull);
      expect(
        harness.budgetRepository.budgets[original.id]!.warningShare,
        isNull,
      );
    });

    test('rejects a zero update allocation without writing', () async {
      final original = testBudget();
      final harness = BudgetTestHarness(
        initialBudgets: {original.id: original},
        initialCategories: {'category-1': testCategory()},
      );

      await expectLater(
        harness.service.updateBudget(
          budget: original,
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
      expect(harness.budgetRepository.updatedIds, isEmpty);
    });

    test('rejects an update for a missing category without writing', () async {
      final original = testBudget();
      final harness = BudgetTestHarness(
        initialBudgets: {original.id: original},
        initialCategories: {'category-1': testCategory()},
      );

      await expectLater(
        harness.service.updateBudget(
          budget: original,
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
      expect(harness.budgetRepository.updatedIds, isEmpty);
    });

    test('rejects an invalid period without writing', () async {
      final original = testBudget();
      final harness = BudgetTestHarness(
        initialBudgets: {original.id: original},
        initialCategories: {'category-1': testCategory()},
      );

      await expectLater(
        harness.service.updateBudget(
          budget: original,
          categoryId: 'category-1',
          allocatedAmountMinorUnits: 1000,
          period: 'sometimes',
          startDate: DateTime.utc(2026, 10),
        ),
        throwsArgumentError,
      );
      expect(harness.budgetRepository.updatedIds, isEmpty);
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

    test('persists the budget currency on create', () async {
      final harness = BudgetTestHarness(
        initialCategories: {'category-1': testCategory()},
      );

      final created = await harness.service.createBudget(
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 5000,
        period: 'monthly',
        startDate: DateTime.utc(2026, 10),
        currency: 'EGP',
      );

      expect(created.currency, 'EGP');
      expect(harness.budgetRepository.budgets.values.single.currency, 'EGP');
    });

    test('regenerates the id when it collides', () async {
      final existing = testBudget();
      var calls = 0;
      final harness = BudgetTestHarness(
        initialBudgets: {existing.id: existing},
        initialCategories: {'category-1': testCategory()},
        newId: () => calls++ == 0 ? 'budget-1' : 'budget-2',
      );

      final created = await harness.service.createBudget(
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 5000,
        period: 'monthly',
        startDate: DateTime.utc(2026, 10),
      );

      expect(created.id, 'budget-2-1');
      expect(harness.budgetRepository.createdIds, <String>['budget-2-1']);
    });

    test('gives up after repeated id collisions', () async {
      final harness = BudgetTestHarness(
        initialBudgets: {
          'budget-1': testBudget(),
          'budget-1-1': testBudget(id: 'budget-1-1'),
          'budget-1-2': testBudget(id: 'budget-1-2'),
          'budget-1-3': testBudget(id: 'budget-1-3'),
          'budget-1-4': testBudget(id: 'budget-1-4'),
          'budget-1-5': testBudget(id: 'budget-1-5'),
        },
        initialCategories: {'category-1': testCategory()},
        newId: () => 'budget-1',
      );

      await expectLater(
        harness.service.createBudget(
          categoryId: 'category-1',
          allocatedAmountMinorUnits: 5000,
          period: 'monthly',
          startDate: DateTime.utc(2026, 10),
        ),
        throwsA(isA<StateError>()),
      );
      expect(harness.budgetRepository.createdIds, isEmpty);
    });

    test('applies the currency passed on update', () async {
      final original = testBudget(currency: 'EGP');
      final harness = BudgetTestHarness(
        initialBudgets: {original.id: original},
        initialCategories: {'category-1': testCategory()},
      );

      final updated = await harness.service.updateBudget(
        budget: original,
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 10000,
        period: 'monthly',
        startDate: DateTime.utc(2026, 10),
        currency: 'USD',
      );

      expect(updated.currency, 'USD');
      expect(harness.budgetRepository.budgets[original.id]!.currency, 'USD');
    });

    test('clears the currency when the update omits it', () async {
      final original = testBudget(currency: 'EGP');
      final harness = BudgetTestHarness(
        initialBudgets: {original.id: original},
        initialCategories: {'category-1': testCategory()},
      );

      final updated = await harness.service.updateBudget(
        budget: original,
        categoryId: 'category-1',
        allocatedAmountMinorUnits: 10000,
        period: 'monthly',
        startDate: DateTime.utc(2026, 10),
      );

      expect(updated.currency, isNull);
      expect(harness.budgetRepository.budgets[original.id]!.currency, isNull);
    });
  });
}
