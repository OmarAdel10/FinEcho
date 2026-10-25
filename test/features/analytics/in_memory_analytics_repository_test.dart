// Test fixtures intentionally repeat constructor defaults for readability.
// ignore_for_file: avoid_redundant_argument_values

import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/analytics_account_total.dart';
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

    test('orders tied categories in SQLite binary order', () async {
      final repository = _build(
        transactions: [
          _transaction(
            'expense-emoji',
            amountMinorUnits: 1000,
            timestamp: DateTime.utc(2026, 1, 5),
            categoryId: 'category-\u{1F600}',
          ),
          _transaction(
            'expense-replacement',
            amountMinorUnits: 1000,
            timestamp: DateTime.utc(2026, 1, 6),
            categoryId: 'category-\uFFFD',
          ),
        ],
        categories: [
          _category('category-\u{1F600}', 'Emoji'),
          _category('category-\uFFFD', 'Replacement'),
        ],
      );

      final summary = await repository.summaryForRange(
        startUtc: DateTime.utc(2026, 1, 1),
        endUtc: DateTime.utc(2026, 2, 1),
      );

      // SQLite orders ids by UTF-8 bytes (code points), so the
      // replacement character (U+FFFD) sorts before the supplementary
      // emoji id — unlike Dart's UTF-16 compareTo.
      expect(
        [for (final total in summary.categoryExpenseTotals) total.categoryId],
        ['category-\uFFFD', 'category-\u{1F600}'],
      );
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

    group('currency filtering', () {
      final startUtc = DateTime.utc(2026, 10, 1);
      final endUtc = DateTime.utc(2026, 11, 1);

      test('filters the summary to the requested currency', () async {
        final repository = _build(
          transactions: <Transaction>[
            _transaction(
              'expense-egp',
              amountMinorUnits: 1000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            _transaction(
              'expense-usd',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 6),
              accountId: 'account-usd',
            ),
            _transaction(
              'income-usd',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 10, 7),
              type: TransactionType.income,
              accountId: 'account-usd',
            ),
          ],
          accounts: <Account>[
            _account('account-1'),
            _account('account-usd', currency: 'USD'),
          ],
        );

        final summary = await repository.summaryForRange(
          startUtc: startUtc,
          endUtc: endUtc,
          currency: 'EGP',
        );

        expect(summary.totalExpenseMinorUnits, 1000);
        expect(summary.totalIncomeMinorUnits, 0);
        expect(summary.categoryExpenseTotals, const [
          CategoryTotal(categoryId: null, name: null, expenseMinorUnits: 1000),
        ]);
        expect(summary.categoryIncomeTotals, isEmpty);
      });

      test('sums every currency when no filter is set', () async {
        final repository = _build(
          transactions: <Transaction>[
            _transaction(
              'expense-egp',
              amountMinorUnits: 1000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            _transaction(
              'expense-usd',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 6),
              accountId: 'account-usd',
            ),
          ],
          accounts: <Account>[_account('account-1')],
        );

        final summary = await repository.summaryForRange(
          startUtc: startUtc,
          endUtc: endUtc,
        );

        expect(summary.totalExpenseMinorUnits, 3000);
      });

      test(
        'ignores transactions without a known account when filtering',
        () async {
          final repository = _build(
            transactions: <Transaction>[
              _transaction(
                'expense-egp',
                amountMinorUnits: 1000,
                timestamp: DateTime.utc(2026, 10, 5),
              ),
              _transaction(
                'expense-orphan',
                amountMinorUnits: 4000,
                timestamp: DateTime.utc(2026, 10, 8),
                accountId: 'account-gone',
              ),
            ],
            accounts: <Account>[_account('account-1')],
          );

          final summary = await repository.summaryForRange(
            startUtc: startUtc,
            endUtc: endUtc,
            currency: 'EGP',
          );

          expect(summary.totalExpenseMinorUnits, 1000);
        },
      );

      test('reports the account currency on account totals', () async {
        final repository = _build(
          transactions: <Transaction>[
            _transaction(
              'expense-egp',
              amountMinorUnits: 1000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            _transaction(
              'expense-usd',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 6),
              accountId: 'account-usd',
            ),
            _transaction(
              'expense-orphan',
              amountMinorUnits: 4000,
              timestamp: DateTime.utc(2026, 10, 8),
              accountId: 'account-gone',
            ),
          ],
          accounts: <Account>[
            _account('account-1'),
            _account('account-usd', currency: 'USD'),
          ],
        );

        final totals = await repository.accountTotalsForRange(
          startUtc: startUtc,
          endUtc: endUtc,
        );

        expect(totals, hasLength(2));
        expect(
          totals,
          contains(
            predicate<AnalyticsAccountTotal>(
              (total) =>
                  total.accountId == 'account-1' &&
                  total.currency == 'EGP' &&
                  total.expenseMinorUnits == 1000,
            ),
          ),
        );
        expect(
          totals,
          contains(
            predicate<AnalyticsAccountTotal>(
              (total) =>
                  total.accountId == 'account-usd' &&
                  total.currency == 'USD' &&
                  total.expenseMinorUnits == 2000,
            ),
          ),
        );
      });

      test('filters expense category totals by currency', () async {
        final repository = _build(
          transactions: <Transaction>[
            _transaction(
              'expense-egp',
              amountMinorUnits: 1000,
              timestamp: DateTime.utc(2026, 10, 5),
              categoryId: 'category-1',
            ),
            _transaction(
              'expense-usd',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 6),
              categoryId: 'category-1',
              accountId: 'account-usd',
            ),
          ],
          accounts: <Account>[
            _account('account-1'),
            _account('account-usd', currency: 'USD'),
          ],
        );

        final totals = await repository.expenseTotalsByCategoryForRange(
          startUtc: startUtc,
          endUtc: endUtc,
          currency: 'EGP',
        );

        expect(totals, hasLength(1));
        expect(totals.single.categoryId, 'category-1');
        expect(totals.single.totalMinorUnits, 1000);
      });

      test('filters monthly expense totals by currency', () async {
        final repository = _build(
          transactions: <Transaction>[
            _transaction(
              'expense-egp',
              amountMinorUnits: 1000,
              timestamp: DateTime.utc(2026, 10, 5),
              categoryId: 'category-1',
            ),
            _transaction(
              'expense-usd',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 6),
              categoryId: 'category-1',
              accountId: 'account-usd',
            ),
          ],
          accounts: <Account>[
            _account('account-1'),
            _account('account-usd', currency: 'USD'),
          ],
        );

        final totals = await repository.expenseMonthlyTotalsByCategory(
          startUtc: startUtc,
          endUtc: endUtc,
          currency: 'EGP',
        );

        expect(totals, hasLength(1));
        expect(totals.single.totalMinorUnits, 1000);
      });

      test('filters expense transactions by currency', () async {
        final repository = _build(
          transactions: <Transaction>[
            _transaction(
              'expense-egp',
              amountMinorUnits: 1000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            _transaction(
              'expense-usd',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 6),
              accountId: 'account-usd',
            ),
          ],
          accounts: <Account>[
            _account('account-1'),
            _account('account-usd', currency: 'USD'),
          ],
        );

        final transactions = await repository.expenseTransactionsForRange(
          startUtc: startUtc,
          endUtc: endUtc,
          currency: 'USD',
        );

        expect(transactions, hasLength(1));
        expect(transactions.single.id, 'expense-usd');
      });
    });
  });
}

InMemoryAnalyticsRepository _build({
  List<Transaction> transactions = const <Transaction>[],
  List<Category> categories = const <Category>[],
  List<Account> accounts = const <Account>[],
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
    accounts: FakeAccountRepository(
      initialAccounts: {for (final account in accounts) account.id: account},
    ),
  );
}

Transaction _transaction(
  String id, {
  required int amountMinorUnits,
  required DateTime timestamp,
  TransactionType type = TransactionType.expense,
  String? categoryId,
  String accountId = 'account-1',
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    categoryId: categoryId,
    amountMinorUnits: amountMinorUnits,
    timestamp: timestamp,
    type: type,
    source: TransactionSource.manual,
  );
}

Account _account(String id, {String currency = 'EGP'}) {
  return Account(
    id: id,
    name: 'Account $id',
    type: AccountType.cash,
    currency: currency,
    balanceMinorUnits: 0,
  );
}

Category _category(String id, String name) {
  return Category(id: id, name: name, iconKey: 'category', colorHex: '#22C55E');
}
