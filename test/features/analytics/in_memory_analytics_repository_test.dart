// Test fixtures intentionally repeat constructor defaults for readability.
// ignore_for_file: avoid_redundant_argument_values

import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/analytics/data/repositories/in_memory_analytics_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../transactions/fake_transaction_repositories.dart';

void main() {
  group('InMemoryAnalyticsRepository', () {
    test('summarizes a UTC range and excludes transfers', () async {
      final repository = _build(
        transactions: [
          _transaction(
            'income-in-range',
            amountMinorUnits: 120000,
            timestamp: DateTime.utc(2026, 1, 10),
            type: TransactionType.income,
          ),
          _transaction(
            'expense-food',
            amountMinorUnits: 40000,
            timestamp: DateTime.utc(2026, 1, 15),
            categoryId: 'category-food',
          ),
          _transaction(
            'expense-transport',
            amountMinorUnits: 20000,
            timestamp: DateTime.utc(2026, 1, 20),
            categoryId: 'category-transport',
          ),
          _transaction(
            'expense-uncategorized',
            amountMinorUnits: 5000,
            timestamp: DateTime.utc(2026, 1, 25),
          ),
          _transaction(
            'transfer-in-range',
            amountMinorUnits: 100000,
            timestamp: DateTime.utc(2026, 1, 30),
            type: TransactionType.transfer,
          ),
          _transaction(
            'expense-before-range',
            amountMinorUnits: 10000,
            timestamp: DateTime.utc(2025, 12, 31, 23, 59, 59),
          ),
          _transaction(
            'expense-at-end',
            amountMinorUnits: 10000,
            timestamp: DateTime.utc(2026, 2, 1),
          ),
        ],
        categories: [
          _category('category-food', 'Food'),
          _category('category-transport', 'Transport'),
        ],
      );

      final summary = await repository.summaryForRange(
        startUtc: DateTime.utc(2026, 1, 1),
        endUtc: DateTime.utc(2026, 2, 1),
      );

      expect(summary.startUtc, DateTime.utc(2026, 1, 1));
      expect(summary.endUtc, DateTime.utc(2026, 2, 1));
      expect(summary.totalIncomeMinorUnits, 120000);
      expect(summary.totalExpenseMinorUnits, 65000);
      expect(summary.netAmountMinorUnits, 55000);
      expect(summary.categoryExpenseTotals, <CategoryTotal>[
        const CategoryTotal(
          categoryId: 'category-food',
          name: 'Food',
          expenseMinorUnits: 40000,
        ),
        const CategoryTotal(
          categoryId: 'category-transport',
          name: 'Transport',
          expenseMinorUnits: 20000,
        ),
        const CategoryTotal(
          categoryId: null,
          name: null,
          expenseMinorUnits: 5000,
        ),
      ]);
    });

    test('accumulates repeated transactions per category and type', () async {
      final repository = _build(
        transactions: [
          _transaction(
            'expense-food-1',
            amountMinorUnits: 40000,
            timestamp: DateTime.utc(2026, 1, 10),
            categoryId: 'category-food',
          ),
          _transaction(
            'expense-food-2',
            amountMinorUnits: 2500,
            timestamp: DateTime.utc(2026, 1, 12),
            categoryId: 'category-food',
          ),
          _transaction(
            'income-1',
            amountMinorUnits: 120000,
            timestamp: DateTime.utc(2026, 1, 11),
            type: TransactionType.income,
          ),
          _transaction(
            'income-2',
            amountMinorUnits: 30000,
            timestamp: DateTime.utc(2026, 1, 13),
            type: TransactionType.income,
          ),
        ],
        categories: [_category('category-food', 'Food')],
      );

      final summary = await repository.summaryForRange(
        startUtc: DateTime.utc(2026, 1, 1),
        endUtc: DateTime.utc(2026, 2, 1),
      );

      expect(summary.totalIncomeMinorUnits, 150000);
      expect(summary.totalExpenseMinorUnits, 42500);
      expect(summary.categoryExpenseTotals, <CategoryTotal>[
        const CategoryTotal(
          categoryId: 'category-food',
          name: 'Food',
          expenseMinorUnits: 42500,
        ),
      ]);
      expect(summary.categoryIncomeTotals, <CategoryTotal>[
        const CategoryTotal(
          categoryId: null,
          name: null,
          expenseMinorUnits: 0,
          incomeMinorUnits: 150000,
        ),
      ]);
    });

    test('breaks income down by category, highest first', () async {
      final repository = _build(
        transactions: [
          _transaction(
            'income-salary',
            amountMinorUnits: 200000,
            timestamp: DateTime.utc(2026, 1, 5),
            type: TransactionType.income,
            categoryId: 'category-salary',
          ),
          _transaction(
            'income-freelance',
            amountMinorUnits: 75000,
            timestamp: DateTime.utc(2026, 1, 8),
            type: TransactionType.income,
            categoryId: 'category-freelance',
          ),
          _transaction(
            'income-freelance-2',
            amountMinorUnits: 25000,
            timestamp: DateTime.utc(2026, 1, 9),
            type: TransactionType.income,
            categoryId: 'category-freelance',
          ),
        ],
        categories: [
          _category('category-salary', 'Salary'),
          _category('category-freelance', 'Freelance'),
        ],
      );

      final summary = await repository.summaryForRange(
        startUtc: DateTime.utc(2026, 1, 1),
        endUtc: DateTime.utc(2026, 2, 1),
      );

      expect(summary.categoryIncomeTotals, <CategoryTotal>[
        const CategoryTotal(
          categoryId: 'category-salary',
          name: 'Salary',
          expenseMinorUnits: 0,
          incomeMinorUnits: 200000,
        ),
        const CategoryTotal(
          categoryId: 'category-freelance',
          name: 'Freelance',
          expenseMinorUnits: 0,
          incomeMinorUnits: 100000,
        ),
      ]);
      // Expenses stay separate from the income breakdown.
      expect(summary.categoryExpenseTotals, isEmpty);
    });

    test(
      'includes the start and excludes the end of the half-open range',
      () async {
        final repository = _build(
          transactions: [
            _transaction(
              'income-at-start',
              amountMinorUnits: 1000,
              timestamp: DateTime.utc(2026, 1, 1),
              type: TransactionType.income,
            ),
            _transaction(
              'income-before-start',
              amountMinorUnits: 4000,
              timestamp: DateTime.utc(2025, 12, 31, 23, 59, 59, 999),
              type: TransactionType.income,
            ),
            _transaction(
              'income-at-end',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 2, 1),
              type: TransactionType.income,
            ),
          ],
        );

        final summary = await repository.summaryForRange(
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 2, 1),
        );

        expect(summary.totalIncomeMinorUnits, 1000);
        expect(summary.totalExpenseMinorUnits, 0);
      },
    );

    test(
      'orders category totals by expense then uncategorized then id',
      () async {
        final repository = _build(
          transactions: [
            _transaction(
              'expense-category-b',
              amountMinorUnits: 5000,
              timestamp: DateTime.utc(2026, 1, 10),
              categoryId: 'category-b',
            ),
            _transaction(
              'expense-uncategorized',
              amountMinorUnits: 5000,
              timestamp: DateTime.utc(2026, 1, 11),
            ),
            _transaction(
              'expense-category-a',
              amountMinorUnits: 5000,
              timestamp: DateTime.utc(2026, 1, 12),
              categoryId: 'category-a',
            ),
            _transaction(
              'expense-category-c',
              amountMinorUnits: 40000,
              timestamp: DateTime.utc(2026, 1, 13),
              categoryId: 'category-c',
            ),
          ],
          categories: [
            _category('category-a', 'A'),
            _category('category-b', 'B'),
            _category('category-c', 'C'),
          ],
        );

        final summary = await repository.summaryForRange(
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 2, 1),
        );

        expect(summary.categoryExpenseTotals, <CategoryTotal>[
          const CategoryTotal(
            categoryId: 'category-c',
            name: 'C',
            expenseMinorUnits: 40000,
          ),
          const CategoryTotal(
            categoryId: 'category-a',
            name: 'A',
            expenseMinorUnits: 5000,
          ),
          const CategoryTotal(
            categoryId: 'category-b',
            name: 'B',
            expenseMinorUnits: 5000,
          ),
          const CategoryTotal(
            categoryId: null,
            name: null,
            expenseMinorUnits: 5000,
          ),
        ]);
      },
    );

    test(
      'keeps a null name for a category missing from the repository',
      () async {
        final repository = _build(
          transactions: [
            _transaction(
              'expense-missing-category',
              amountMinorUnits: 7000,
              timestamp: DateTime.utc(2026, 1, 10),
              categoryId: 'category-missing',
            ),
          ],
        );

        final summary = await repository.summaryForRange(
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 2, 1),
        );

        expect(summary.categoryExpenseTotals, const <CategoryTotal>[
          CategoryTotal(
            categoryId: 'category-missing',
            name: null,
            expenseMinorUnits: 7000,
          ),
        ]);
      },
    );

    test(
      'returns zero totals and no category rows for an empty range',
      () async {
        final repository = _build(
          transactions: [
            _transaction(
              'expense-outside-range',
              amountMinorUnits: 9000,
              timestamp: DateTime.utc(2026, 3, 1),
            ),
          ],
        );

        final summary = await repository.summaryForRange(
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 2, 1),
        );

        expect(summary.totalIncomeMinorUnits, 0);
        expect(summary.totalExpenseMinorUnits, 0);
        expect(summary.netAmountMinorUnits, 0);
        expect(summary.categoryExpenseTotals, isEmpty);
      },
    );

    test('rejects a non-UTC start', () async {
      final repository = _build();

      await expectLater(
        repository.summaryForRange(
          startUtc: DateTime(2026, 1, 1),
          endUtc: DateTime.utc(2026, 2, 1),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a non-UTC end', () async {
      final repository = _build();

      await expectLater(
        repository.summaryForRange(
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime(2026, 2, 1),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a start that is not before the end', () async {
      final repository = _build();

      await expectLater(
        repository.summaryForRange(
          startUtc: DateTime.utc(2026, 2, 1),
          endUtc: DateTime.utc(2026, 1, 1),
        ),
        throwsArgumentError,
      );
      await expectLater(
        repository.summaryForRange(
          startUtc: DateTime.utc(2026, 1, 1),
          endUtc: DateTime.utc(2026, 1, 1),
        ),
        throwsArgumentError,
      );
    });
  });
}

InMemoryAnalyticsRepository _build({
  List<Transaction> transactions = const <Transaction>[],
  List<Category> categories = const <Category>[],
}) {
  return InMemoryAnalyticsRepository(
    transactions: FakeTransactionRepository(
      initialTransactions: {
        for (final transaction in transactions) transaction.id: transaction,
      },
    ),
    categories: FakeCategoryRepository(
      initialCategories: {
        for (final category in categories) category.id: category,
      },
    ),
  );
}

Transaction _transaction(
  String id, {
  required int amountMinorUnits,
  required DateTime timestamp,
  TransactionType type = TransactionType.expense,
  String? categoryId,
}) {
  return Transaction(
    id: id,
    accountId: 'account-1',
    categoryId: categoryId,
    amountMinorUnits: amountMinorUnits,
    timestamp: timestamp,
    type: type,
    source: TransactionSource.manual,
  );
}

Category _category(String id, String name) {
  return Category(id: id, name: name, iconKey: 'category', colorHex: '#22C55E');
}
