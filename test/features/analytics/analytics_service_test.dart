import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/analytics/view_model/models/account_total.dart';
import 'package:finecho/features/analytics/view_model/models/budget_progress.dart';
import 'package:finecho/features/analytics/view_model/models/category_spike.dart';
import 'package:finecho/features/analytics/view_model/models/recurring_charge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../budget/fake_budget_repositories.dart';
import 'fake_analytics_repositories.dart';

void main() {
  group('AnalyticsService', () {
    group('summary ranges', () {
      test('loads the monthly range and its previous month', () async {
        final harness = AnalyticsTestHarness(
          onSummary: (startUtc, endUtc) => _summary(
            startUtc: startUtc,
            endUtc: endUtc,
            income: startUtc == DateTime.utc(2026, 10) ? 200000 : 100000,
            expense: startUtc == DateTime.utc(2026, 10) ? 150000 : 100000,
            categoryTotals: const [
              CategoryTotal(
                categoryId: 'category-1',
                name: 'Food',
                expenseMinorUnits: 42000,
              ),
            ],
          ),
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(harness.analyticsRepository.requestedRanges, [
          (DateTime.utc(2026, 10), DateTime.utc(2026, 11)),
          (DateTime.utc(2026, 9), DateTime.utc(2026, 9, 15, 12)),
        ]);
        expect(dashboard.period, AnalyticsPeriod.month);
        expect(dashboard.startUtc, DateTime.utc(2026, 10));
        expect(dashboard.endUtc, DateTime.utc(2026, 11));
        expect(dashboard.totalIncomeMinorUnits, 200000);
        expect(dashboard.totalExpenseMinorUnits, 150000);
        expect(dashboard.netAmountMinorUnits, 50000);
        expect(dashboard.previousExpenseMinorUnits, 100000);
        expect(dashboard.expenseChangeRatio, 0.5);
        expect(dashboard.categoryTotals, const [
          CategoryTotal(
            categoryId: 'category-1',
            name: 'Food',
            expenseMinorUnits: 42000,
          ),
        ]);
      });

      test('uses the local calendar for the month boundary', () async {
        // Nov 1, 00:30 EEST is still Oct 31 in UTC; the dashboard must
        // follow the user's local month, not the UTC month (FINECHO-22).
        final harness = AnalyticsTestHarness(
          now: () => DateTime.utc(2026, 10, 31, 21, 30),
          localUtcOffset: const Duration(hours: 3),
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.startUtc, DateTime.utc(2026, 10, 31, 21));
        expect(dashboard.endUtc, DateTime.utc(2026, 11, 30, 21));
        expect(harness.analyticsRepository.requestedRanges.first, (
          DateTime.utc(2026, 10, 31, 21),
          DateTime.utc(2026, 11, 30, 21),
        ));
      });

      test('derives the previous month from the local calendar', () async {
        final harness = AnalyticsTestHarness(
          now: () => DateTime.utc(2026, 10, 31, 21, 30),
          localUtcOffset: const Duration(hours: 3),
        );

        await harness.service.loadDashboard(period: AnalyticsPeriod.month);

        expect(harness.analyticsRepository.requestedRanges, [
          (DateTime.utc(2026, 10, 31, 21), DateTime.utc(2026, 11, 30, 21)),
          // The comparison runs only for the elapsed half hour of the new
          // local month, measured from the local boundary.
          (DateTime.utc(2026, 9, 30, 21), DateTime.utc(2026, 9, 30, 21, 30)),
        ]);
      });

      test('uses the local calendar for the week boundary', () async {
        // Mon Nov 2 2026, 00:30 EEST = Sun Nov 1, 21:30 UTC. The local week
        // starts on Monday Nov 2 local time, not the UTC week of Oct 26.
        final harness = AnalyticsTestHarness(
          now: () => DateTime.utc(2026, 11, 1, 21, 30),
          localUtcOffset: const Duration(hours: 3),
        );

        await harness.service.loadDashboard(period: AnalyticsPeriod.week);

        expect(harness.analyticsRepository.requestedRanges.first, (
          DateTime.utc(2026, 11, 1, 21),
          DateTime.utc(2026, 11, 8, 21),
        ));
      });

      test('reports no change ratio without previous expenses', () async {
        final harness = AnalyticsTestHarness(
          onSummary: (startUtc, endUtc) => _summary(
            startUtc: startUtc,
            endUtc: endUtc,
            expense: startUtc == DateTime.utc(2026, 10) ? 150000 : 0,
          ),
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.previousExpenseMinorUnits, 0);
        expect(dashboard.expenseChangeRatio, isNull);
      });

      test('loads the week starting on Monday and its previous week', () async {
        final harness = AnalyticsTestHarness();

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.week,
        );

        expect(harness.analyticsRepository.requestedRanges, [
          (DateTime.utc(2026, 10, 12), DateTime.utc(2026, 10, 19)),
          (DateTime.utc(2026, 10, 5), DateTime.utc(2026, 10, 8, 12)),
        ]);
        expect(dashboard.startUtc, DateTime.utc(2026, 10, 12));
        expect(dashboard.endUtc, DateTime.utc(2026, 10, 19));
      });

      test('loads the calendar year and its previous year', () async {
        final harness = AnalyticsTestHarness();

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.year,
        );

        expect(harness.analyticsRepository.requestedRanges, [
          (DateTime.utc(2026), DateTime.utc(2027)),
          (DateTime.utc(2025), DateTime.utc(2025, 10, 15, 12)),
        ]);
        expect(dashboard.startUtc, DateTime.utc(2026));
        expect(dashboard.endUtc, DateTime.utc(2027));
      });

      test('rolls month ranges across the year boundary', () async {
        final december = AnalyticsTestHarness(
          onSummary: (startUtc, endUtc) =>
              _summary(startUtc: startUtc, endUtc: endUtc),
          now: () => DateTime.utc(2026, 12, 15),
        );

        await december.service.loadDashboard(period: AnalyticsPeriod.month);

        expect(december.analyticsRepository.requestedRanges, [
          (DateTime.utc(2026, 12), DateTime.utc(2027)),
          (DateTime.utc(2026, 11), DateTime.utc(2026, 11, 15)),
        ]);
      });

      test('uses the previous December in January', () async {
        final january = AnalyticsTestHarness(
          onSummary: (startUtc, endUtc) =>
              _summary(startUtc: startUtc, endUtc: endUtc),
          now: () => DateTime.utc(2027, 1, 15),
        );

        await january.service.loadDashboard(period: AnalyticsPeriod.month);

        expect(january.analyticsRepository.requestedRanges, [
          (DateTime.utc(2027), DateTime.utc(2027, 2)),
          (DateTime.utc(2026, 12), DateTime.utc(2026, 12, 15)),
        ]);
      });

      test('clamps the previous month to its end when it is shorter', () async {
        final march = AnalyticsTestHarness(
          onSummary: (startUtc, endUtc) =>
              _summary(startUtc: startUtc, endUtc: endUtc),
          now: () => DateTime.utc(2026, 3, 31),
        );

        await march.service.loadDashboard(period: AnalyticsPeriod.month);

        expect(march.analyticsRepository.requestedRanges, [
          (DateTime.utc(2026, 3), DateTime.utc(2026, 4)),
          (DateTime.utc(2026, 2), DateTime.utc(2026, 3)),
        ]);
      });

      test('clamps the previous year to its end when it is shorter', () async {
        final december = AnalyticsTestHarness(
          onSummary: (startUtc, endUtc) =>
              _summary(startUtc: startUtc, endUtc: endUtc),
          now: () => DateTime.utc(2028, 12, 31, 23, 59),
        );

        await december.service.loadDashboard(period: AnalyticsPeriod.year);

        expect(december.analyticsRepository.requestedRanges, [
          (DateTime.utc(2028), DateTime.utc(2029)),
          (DateTime.utc(2027), DateTime.utc(2028)),
        ]);
      });

      test('skips the previous comparison at a period start', () async {
        final harness = AnalyticsTestHarness(
          onSummary: (startUtc, endUtc) =>
              _summary(startUtc: startUtc, endUtc: endUtc),
          now: () => DateTime.utc(2026, 11),
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(harness.analyticsRepository.requestedRanges, [
          (DateTime.utc(2026, 11), DateTime.utc(2026, 12)),
        ]);
        expect(dashboard.previousExpenseMinorUnits, 0);
        expect(dashboard.expenseChangeRatio, isNull);
      });

      test('propagates repository failures', () async {
        final harness = AnalyticsTestHarness();
        harness.analyticsRepository.error = Exception('boom');

        await expectLater(
          harness.service.loadDashboard(period: AnalyticsPeriod.month),
          throwsA(isA<Error>()),
        );
      });
    });

    group('repository failures', () {
      test('propagates transaction load failures', () async {
        final harness = AnalyticsTestHarness();
        harness.transactionRepository.listError = Exception('boom');

        await expectLater(
          harness.service.loadDashboard(period: AnalyticsPeriod.month),
          throwsA(isA<Error>()),
        );
      });

      test('propagates account load failures', () async {
        final harness = AnalyticsTestHarness();
        harness.accountRepository.listError = Exception('boom');

        await expectLater(
          harness.service.loadDashboard(period: AnalyticsPeriod.month),
          throwsA(isA<Error>()),
        );
      });

      test('propagates budget load failures', () async {
        final harness = AnalyticsTestHarness();
        harness.budgetRepository.listError = Exception('boom');

        await expectLater(
          harness.service.loadDashboard(period: AnalyticsPeriod.month),
          throwsA(isA<Error>()),
        );
      });

      test('propagates category load failures', () async {
        final harness = AnalyticsTestHarness();
        harness.categoryRepository.listError = Exception('boom');

        await expectLater(
          harness.service.loadDashboard(period: AnalyticsPeriod.month),
          throwsA(isA<Error>()),
        );
      });
    });

    group('account totals', () {
      test('totals income and expenses per account within the range', () async {
        final harness = AnalyticsTestHarness(
          initialAccounts: {
            'account-1': testAccount(),
            'account-2': testAccount(id: 'account-2', name: 'Bank'),
          },
          initialTransactions: {
            't1': testTransaction(
              id: 't1',
              timestamp: DateTime.utc(2026, 10, 5),
              amountMinorUnits: 10000,
            ),
            't2': testTransaction(
              id: 't2',
              timestamp: DateTime.utc(2026, 10, 6),
              amountMinorUnits: 20000,
              type: TransactionType.income,
            ),
            't3': testTransaction(
              id: 't3',
              timestamp: DateTime.utc(2026, 10, 8),
              amountMinorUnits: 10000,
              accountId: 'account-2',
            ),
            't4': testTransaction(
              id: 't4',
              timestamp: DateTime.utc(2026, 10, 9),
              amountMinorUnits: 9000,
              type: TransactionType.transfer,
            ),
            't5': testTransaction(
              id: 't5',
              timestamp: DateTime.utc(2026, 9, 30),
              amountMinorUnits: 7000,
            ),
            't6': testTransaction(
              id: 't6',
              timestamp: DateTime.utc(2026, 10, 9),
              amountMinorUnits: 3000,
              accountId: 'account-9',
            ),
            't7': testTransaction(
              id: 't7',
              timestamp: DateTime.utc(2026, 10, 10),
              amountMinorUnits: 5000,
              type: TransactionType.income,
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.accountTotals, const [
          AccountTotal(
            accountId: 'account-1',
            name: 'Cash',
            currency: 'EGP',
            incomeMinorUnits: 25000,
            expenseMinorUnits: 10000,
          ),
          AccountTotal(
            accountId: 'account-2',
            name: 'Bank',
            currency: 'EGP',
            incomeMinorUnits: 0,
            expenseMinorUnits: 10000,
          ),
          AccountTotal(
            accountId: 'account-9',
            name: 'Unknown account',
            currency: 'EGP',
            incomeMinorUnits: 0,
            expenseMinorUnits: 3000,
          ),
        ]);
      });

      test('excludes transfers and out-of-range transactions', () async {
        final harness = AnalyticsTestHarness(
          initialAccounts: {'account-1': testAccount()},
          initialTransactions: {
            't1': testTransaction(
              id: 't1',
              timestamp: DateTime.utc(2026, 10),
              type: TransactionType.transfer,
            ),
            't2': testTransaction(
              id: 't2',
              timestamp: DateTime.utc(2026, 10, 31, 23, 59),
              amountMinorUnits: 2000,
            ),
            't3': testTransaction(
              id: 't3',
              timestamp: DateTime.utc(2026, 11),
              amountMinorUnits: 4000,
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.accountTotals, const [
          AccountTotal(
            accountId: 'account-1',
            name: 'Cash',
            currency: 'EGP',
            incomeMinorUnits: 0,
            expenseMinorUnits: 2000,
          ),
        ]);
      });

      test('orders accounts by name when expenses and income tie', () async {
        final harness = AnalyticsTestHarness(
          initialAccounts: {
            'account-1': testAccount(name: 'Beta'),
            'account-2': testAccount(id: 'account-2', name: 'Alpha'),
          },
          initialTransactions: {
            't1': testTransaction(
              id: 't1',
              timestamp: DateTime.utc(2026, 10, 5),
              amountMinorUnits: 5000,
            ),
            't2': testTransaction(
              id: 't2',
              timestamp: DateTime.utc(2026, 10, 6),
              amountMinorUnits: 5000,
              accountId: 'account-2',
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.accountTotals, const [
          AccountTotal(
            accountId: 'account-2',
            name: 'Alpha',
            currency: 'EGP',
            incomeMinorUnits: 0,
            expenseMinorUnits: 5000,
          ),
          AccountTotal(
            accountId: 'account-1',
            name: 'Beta',
            currency: 'EGP',
            incomeMinorUnits: 0,
            expenseMinorUnits: 5000,
          ),
        ]);
      });

      test('orders accounts by id when every other field ties', () async {
        final harness = AnalyticsTestHarness(
          initialAccounts: {
            'account-1': testAccount(),
            'account-2': testAccount(id: 'account-2'),
          },
          initialTransactions: {
            't1': testTransaction(
              id: 't1',
              timestamp: DateTime.utc(2026, 10, 5),
              amountMinorUnits: 5000,
            ),
            't2': testTransaction(
              id: 't2',
              timestamp: DateTime.utc(2026, 10, 6),
              amountMinorUnits: 5000,
              accountId: 'account-2',
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(
          dashboard.accountTotals.map((total) => total.accountId).toList(),
          ['account-1', 'account-2'],
        );
      });
    });

    group('recurring charges', () {
      test('finds charges repeating across months in the window', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {
            'category-1': testCategory(),
            'category-2': testAnalyticsCategory(
              id: 'category-2',
              name: 'Transport',
            ),
          },
          initialTransactions: {
            'r1': testTransaction(
              id: 'r1',
              categoryId: 'category-1',
              amountMinorUnits: 4530,
              timestamp: DateTime.utc(2026, 9, 10),
              payee: 'Netflix',
            ),
            'r2': testTransaction(
              id: 'r2',
              categoryId: 'category-1',
              amountMinorUnits: 4530,
              timestamp: DateTime.utc(2026, 10, 10),
              payee: 'Netflix',
            ),
            'r3': testTransaction(
              id: 'r3',
              categoryId: 'category-1',
              amountMinorUnits: 8000,
              timestamp: DateTime.utc(2026, 10, 12),
              payee: 'KFC',
            ),
            'r4': testTransaction(
              id: 'r4',
              categoryId: 'category-2',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 8, 15),
              payee: 'Metro',
            ),
            'r5': testTransaction(
              id: 'r5',
              categoryId: 'category-2',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 9, 15),
              payee: 'Metro',
            ),
            'r6': testTransaction(
              id: 'r6',
              categoryId: 'category-2',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 15),
              payee: 'Metro',
            ),
            'r7': testTransaction(
              id: 'r7',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 7, 10),
              payee: 'Steam',
            ),
            'r8': testTransaction(
              id: 'r8',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 9, 12),
              type: TransactionType.income,
              payee: 'Employer',
            ),
            'r9': testTransaction(
              id: 'r9',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 10, 12),
              type: TransactionType.transfer,
              payee: 'Savings',
            ),
            'r10': testTransaction(
              id: 'r10',
              amountMinorUnits: 6000,
              timestamp: DateTime.utc(2026, 9, 20),
              payee: 'Gym',
            ),
            'r11': testTransaction(
              id: 'r11',
              amountMinorUnits: 6000,
              timestamp: DateTime.utc(2026, 10, 14),
              payee: 'Gym',
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.recurringCharges, const [
          RecurringCharge(
            categoryId: 'category-2',
            name: 'Metro',
            amountMinorUnits: 2000,
            monthsSeen: 3,
          ),
          RecurringCharge(
            categoryId: null,
            name: 'Gym',
            amountMinorUnits: 6000,
            monthsSeen: 2,
          ),
          RecurringCharge(
            categoryId: 'category-1',
            name: 'Netflix',
            amountMinorUnits: 4530,
            monthsSeen: 2,
          ),
        ]);
      });

      test('recurs even when the amount changes between months', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {'category-1': testCategory()},
          initialTransactions: {
            'b1': testTransaction(
              id: 'b1',
              categoryId: 'category-1',
              amountMinorUnits: 4575,
              timestamp: DateTime.utc(2026, 9, 10),
              payee: 'Netflix',
            ),
            'b2': testTransaction(
              id: 'b2',
              categoryId: 'category-1',
              amountMinorUnits: 4600,
              timestamp: DateTime.utc(2026, 10, 10),
              payee: 'Netflix',
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.recurringCharges, const [
          RecurringCharge(
            categoryId: 'category-1',
            name: 'Netflix',
            amountMinorUnits: 4600,
            monthsSeen: 2,
          ),
        ]);
      });

      test('drops charges that lapsed before the current month', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {'category-1': testCategory()},
          initialTransactions: {
            'aug': testTransaction(
              id: 'aug',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 8, 10),
              payee: 'Netflix',
            ),
            'sep': testTransaction(
              id: 'sep',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 9, 10),
              payee: 'Netflix',
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.recurringCharges, isEmpty);
      });

      test('ignores charges that skip a month', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {'category-1': testCategory()},
          initialTransactions: {
            'aug': testTransaction(
              id: 'aug',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 8, 10),
              payee: 'Netflix',
            ),
            'oct': testTransaction(
              id: 'oct',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 10, 10),
              payee: 'Netflix',
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.recurringCharges, isEmpty);
      });

      test('ignores transactions without a payee', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {'category-1': testCategory()},
          initialTransactions: {
            'sep': testTransaction(
              id: 'sep',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 9, 10),
            ),
            'oct': testTransaction(
              id: 'oct',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 10, 10),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.recurringCharges, isEmpty);
      });

      test('matches payees regardless of case or padding', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {'category-1': testCategory()},
          initialTransactions: {
            'sep': testTransaction(
              id: 'sep',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 9, 10),
              payee: ' NETFLIX ',
            ),
            'oct': testTransaction(
              id: 'oct',
              categoryId: 'category-1',
              amountMinorUnits: 4600,
              timestamp: DateTime.utc(2026, 10, 10),
              payee: 'netflix',
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.recurringCharges, const [
          RecurringCharge(
            categoryId: 'category-1',
            name: 'netflix',
            amountMinorUnits: 4600,
            monthsSeen: 2,
          ),
        ]);
      });

      test('orders equal charges by payee name', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {
            'category-1': testCategory(),
            'category-2': testAnalyticsCategory(id: 'category-2', name: 'Food'),
          },
          initialTransactions: {
            'alpha-sep': testTransaction(
              id: 'alpha-sep',
              categoryId: 'category-1',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 9, 10),
              payee: 'Alpha Gym',
            ),
            'alpha-oct': testTransaction(
              id: 'alpha-oct',
              categoryId: 'category-1',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 10),
              payee: 'Alpha Gym',
            ),
            'beta-sep': testTransaction(
              id: 'beta-sep',
              categoryId: 'category-2',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 9, 15),
              payee: 'Beta Gym',
            ),
            'beta-oct': testTransaction(
              id: 'beta-oct',
              categoryId: 'category-2',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 15),
              payee: 'Beta Gym',
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(
          dashboard.recurringCharges.map((charge) => charge.name).toList(),
          ['Alpha Gym', 'Beta Gym'],
        );
      });
    });

    group('unusual spikes', () {
      test('flags current spending far above the recent average', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {
            'category-1': testCategory(),
            'category-3': testAnalyticsCategory(
              id: 'category-3',
              name: 'Shopping',
            ),
          },
          initialTransactions: {
            'food-jul': testTransaction(
              id: 'food-jul',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 7, 5),
            ),
            'food-aug': testTransaction(
              id: 'food-aug',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 8, 5),
            ),
            'food-sep': testTransaction(
              id: 'food-sep',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 9, 5),
            ),
            'food-oct': testTransaction(
              id: 'food-oct',
              categoryId: 'category-1',
              amountMinorUnits: 6000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            'shopping-jul': testTransaction(
              id: 'shopping-jul',
              categoryId: 'category-3',
              amountMinorUnits: 9000,
              timestamp: DateTime.utc(2026, 7, 6),
            ),
            'shopping-aug': testTransaction(
              id: 'shopping-aug',
              categoryId: 'category-3',
              amountMinorUnits: 9000,
              timestamp: DateTime.utc(2026, 8, 6),
            ),
            'shopping-sep': testTransaction(
              id: 'shopping-sep',
              categoryId: 'category-3',
              amountMinorUnits: 9000,
              timestamp: DateTime.utc(2026, 9, 6),
            ),
            'shopping-oct': testTransaction(
              id: 'shopping-oct',
              categoryId: 'category-3',
              amountMinorUnits: 13500,
              timestamp: DateTime.utc(2026, 10, 6),
            ),
            'new-category': testTransaction(
              id: 'new-category',
              categoryId: 'category-2',
              amountMinorUnits: 5000,
              timestamp: DateTime.utc(2026, 10, 7),
            ),
            'other-jul': testTransaction(
              id: 'other-jul',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 7, 8),
            ),
            'other-aug': testTransaction(
              id: 'other-aug',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 8, 8),
            ),
            'other-sep': testTransaction(
              id: 'other-sep',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 9, 8),
            ),
            'other-oct': testTransaction(
              id: 'other-oct',
              amountMinorUnits: 4800,
              timestamp: DateTime.utc(2026, 10, 8),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.unusualSpikes, const [
          CategorySpike(
            categoryId: 'category-1',
            name: 'Food',
            currentExpenseMinorUnits: 6000,
            ratio: 2,
          ),
          CategorySpike(
            categoryId: null,
            name: 'Uncategorized',
            currentExpenseMinorUnits: 4800,
            ratio: 1.6,
          ),
          CategorySpike(
            categoryId: 'category-3',
            name: 'Shopping',
            currentExpenseMinorUnits: 13500,
            ratio: 1.5,
          ),
        ]);
      });

      test('ignores categories without a baseline', () async {
        final harness = AnalyticsTestHarness(
          initialTransactions: {
            't1': testTransaction(
              id: 't1',
              categoryId: 'category-2',
              amountMinorUnits: 5000,
              timestamp: DateTime.utc(2026, 10, 7),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.unusualSpikes, isEmpty);
      });

      test('ignores a category with a single baseline month', () async {
        final harness = AnalyticsTestHarness(
          initialTransactions: {
            'sep': testTransaction(
              id: 'sep',
              categoryId: 'category-2',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 9, 5),
            ),
            'oct': testTransaction(
              id: 'oct',
              categoryId: 'category-2',
              amountMinorUnits: 6000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.unusualSpikes, isEmpty);
      });

      test('orders equal ratios by the current expense', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {
            'category-1': testCategory(),
            'category-2': testAnalyticsCategory(
              id: 'category-2',
              name: 'Transport',
            ),
          },
          initialTransactions: {
            'food-jul': testTransaction(
              id: 'food-jul',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 7, 5),
            ),
            'food-aug': testTransaction(
              id: 'food-aug',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 8, 5),
            ),
            'food-sep': testTransaction(
              id: 'food-sep',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 9, 5),
            ),
            'food-oct': testTransaction(
              id: 'food-oct',
              categoryId: 'category-1',
              amountMinorUnits: 6000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            'transport-jul': testTransaction(
              id: 'transport-jul',
              categoryId: 'category-2',
              amountMinorUnits: 4000,
              timestamp: DateTime.utc(2026, 7, 6),
            ),
            'transport-aug': testTransaction(
              id: 'transport-aug',
              categoryId: 'category-2',
              amountMinorUnits: 4000,
              timestamp: DateTime.utc(2026, 8, 6),
            ),
            'transport-sep': testTransaction(
              id: 'transport-sep',
              categoryId: 'category-2',
              amountMinorUnits: 4000,
              timestamp: DateTime.utc(2026, 9, 6),
            ),
            'transport-oct': testTransaction(
              id: 'transport-oct',
              categoryId: 'category-2',
              amountMinorUnits: 8000,
              timestamp: DateTime.utc(2026, 10, 6),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.unusualSpikes, const [
          CategorySpike(
            categoryId: 'category-2',
            name: 'Transport',
            currentExpenseMinorUnits: 8000,
            ratio: 2,
          ),
          CategorySpike(
            categoryId: 'category-1',
            name: 'Food',
            currentExpenseMinorUnits: 6000,
            ratio: 2,
          ),
        ]);
      });

      test('orders equal spikes by category id', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {
            'category-1': testCategory(),
            'category-2': testAnalyticsCategory(id: 'category-2', name: 'Food'),
          },
          initialTransactions: {
            'first-jul': testTransaction(
              id: 'first-jul',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 7, 5),
            ),
            'first-aug': testTransaction(
              id: 'first-aug',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 8, 5),
            ),
            'first-sep': testTransaction(
              id: 'first-sep',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 9, 5),
            ),
            'first-oct': testTransaction(
              id: 'first-oct',
              categoryId: 'category-1',
              amountMinorUnits: 6000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            'second-jul': testTransaction(
              id: 'second-jul',
              categoryId: 'category-2',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 7, 6),
            ),
            'second-aug': testTransaction(
              id: 'second-aug',
              categoryId: 'category-2',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 8, 6),
            ),
            'second-sep': testTransaction(
              id: 'second-sep',
              categoryId: 'category-2',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 9, 6),
            ),
            'second-oct': testTransaction(
              id: 'second-oct',
              categoryId: 'category-2',
              amountMinorUnits: 6000,
              timestamp: DateTime.utc(2026, 10, 6),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(
          dashboard.unusualSpikes.map((spike) => spike.categoryId).toList(),
          ['category-1', 'category-2'],
        );
      });
    });

    group('forecast', () {
      test('projects the month end from the current month expenses', () async {
        final harness = AnalyticsTestHarness(
          initialTransactions: {
            'oct': testTransaction(
              id: 'oct',
              amountMinorUnits: 100000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            'income': testTransaction(
              id: 'income',
              amountMinorUnits: 50000,
              timestamp: DateTime.utc(2026, 10, 6),
              type: TransactionType.income,
            ),
            'sep': testTransaction(
              id: 'sep',
              amountMinorUnits: 99999,
              timestamp: DateTime.utc(2026, 9, 30),
            ),
            'nov': testTransaction(
              id: 'nov',
              amountMinorUnits: 500,
              timestamp: DateTime.utc(2026, 11),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.forecast.elapsedDays, 15);
        expect(dashboard.forecast.daysInMonth, 31);
        expect(dashboard.forecast.expenseSoFarMinorUnits, 100000);
        expect(dashboard.forecast.projectedExpenseMinorUnits, 213793);
      });

      test('projects the calendar month for every selected period', () async {
        final harness = AnalyticsTestHarness(
          initialTransactions: {
            'oct': testTransaction(
              id: 'oct',
              amountMinorUnits: 150000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.week,
        );

        expect(dashboard.forecast.expenseSoFarMinorUnits, 150000);
        expect(dashboard.forecast.projectedExpenseMinorUnits, 320690);
      });

      test('does not extrapolate at the start of the month', () async {
        final harness = AnalyticsTestHarness(
          now: () => DateTime.utc(2026, 11),
          initialTransactions: {
            'nov': testTransaction(
              id: 'nov',
              amountMinorUnits: 5000,
              timestamp: DateTime.utc(2026, 11),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.forecast.elapsedDays, 1);
        expect(dashboard.forecast.daysInMonth, 30);
        expect(dashboard.forecast.expenseSoFarMinorUnits, 5000);
        expect(dashboard.forecast.projectedExpenseMinorUnits, 5000);
      });

      test('clamps the first-day denominator to one day', () async {
        final harness = AnalyticsTestHarness(
          now: () => DateTime.utc(2026, 11, 1, 0, 15),
          initialTransactions: {
            'nov': testTransaction(
              id: 'nov',
              amountMinorUnits: 5000,
              timestamp: DateTime.utc(2026, 11),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.forecast.expenseSoFarMinorUnits, 5000);
        expect(dashboard.forecast.projectedExpenseMinorUnits, 150000);
      });

      test('projects the spent total on the last day of the month', () async {
        final harness = AnalyticsTestHarness(
          now: () => DateTime.utc(2026, 10, 31),
          initialTransactions: {
            'oct': testTransaction(
              id: 'oct',
              amountMinorUnits: 100000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.forecast.elapsedDays, 31);
        expect(dashboard.forecast.projectedExpenseMinorUnits, 103333);
      });
    });

    group('budget progress', () {
      test('reports and sorts spending against every budget window', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {
            'category-1': testCategory(),
            'category-2': testAnalyticsCategory(
              id: 'category-2',
              name: 'Transport',
            ),
            'category-3': testAnalyticsCategory(
              id: 'category-3',
              name: 'Shopping',
            ),
            'category-4': testAnalyticsCategory(
              id: 'category-4',
              name: 'Entertainment',
            ),
            'category-5': testAnalyticsCategory(
              id: 'category-5',
              name: 'Utilities',
            ),
            'category-6': testAnalyticsCategory(
              id: 'category-6',
              name: 'Health',
            ),
          },
          initialBudgets: {
            'budget-1': testBudget(allocatedAmountMinorUnits: 100000),
            'budget-2': testBudget(
              id: 'budget-2',
              categoryId: 'category-2',
              allocatedAmountMinorUnits: 100000,
            ),
            'budget-3': testBudget(
              id: 'budget-3',
              categoryId: 'category-3',
              allocatedAmountMinorUnits: 5000,
              period: BudgetPeriod.daily,
            ),
            'budget-4': testBudget(
              id: 'budget-4',
              categoryId: 'category-4',
              allocatedAmountMinorUnits: 70000,
              period: BudgetPeriod.weekly,
              startDate: DateTime.utc(2026, 10, 12),
            ),
            'budget-5': testBudget(
              id: 'budget-5',
              categoryId: 'category-5',
              allocatedAmountMinorUnits: 0,
            ),
            'budget-6': testBudget(
              id: 'budget-6',
              categoryId: 'category-6',
              allocatedAmountMinorUnits: 1000000,
              period: BudgetPeriod.yearly,
              startDate: DateTime.utc(2026),
            ),
            'budget-7': testBudget(
              id: 'budget-7',
              categoryId: 'category-9',
              allocatedAmountMinorUnits: 1000,
            ),
          },
          initialTransactions: {
            'food': testTransaction(
              id: 'food',
              categoryId: 'category-1',
              amountMinorUnits: 90000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            'transport': testTransaction(
              id: 'transport',
              categoryId: 'category-2',
              amountMinorUnits: 120000,
              timestamp: DateTime.utc(2026, 10, 6),
            ),
            'shopping-today': testTransaction(
              id: 'shopping-today',
              categoryId: 'category-3',
              timestamp: DateTime.utc(2026, 10, 15),
            ),
            'shopping-yesterday': testTransaction(
              id: 'shopping-yesterday',
              categoryId: 'category-3',
              amountMinorUnits: 500,
              timestamp: DateTime.utc(2026, 10, 14),
            ),
            'entertainment-week': testTransaction(
              id: 'entertainment-week',
              categoryId: 'category-4',
              amountMinorUnits: 35000,
              timestamp: DateTime.utc(2026, 10, 12),
            ),
            'entertainment-old': testTransaction(
              id: 'entertainment-old',
              categoryId: 'category-4',
              amountMinorUnits: 20000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            'health-mar': testTransaction(
              id: 'health-mar',
              categoryId: 'category-6',
              amountMinorUnits: 500000,
              timestamp: DateTime.utc(2026, 3, 10),
            ),
            'health-aug': testTransaction(
              id: 'health-aug',
              categoryId: 'category-6',
              amountMinorUnits: 350000,
              timestamp: DateTime.utc(2026, 8, 10),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.budgetProgress, const [
          BudgetProgress(
            budgetId: 'budget-2',
            categoryId: 'category-2',
            categoryName: 'Transport',
            allocatedAmountMinorUnits: 100000,
            spentAmountMinorUnits: 120000,
            level: BudgetProgressLevel.exceeded,
          ),
          BudgetProgress(
            budgetId: 'budget-1',
            categoryId: 'category-1',
            categoryName: 'Food',
            allocatedAmountMinorUnits: 100000,
            spentAmountMinorUnits: 90000,
            level: BudgetProgressLevel.warning,
          ),
          BudgetProgress(
            budgetId: 'budget-6',
            categoryId: 'category-6',
            categoryName: 'Health',
            allocatedAmountMinorUnits: 1000000,
            spentAmountMinorUnits: 850000,
            level: BudgetProgressLevel.warning,
          ),
          BudgetProgress(
            budgetId: 'budget-4',
            categoryId: 'category-4',
            categoryName: 'Entertainment',
            allocatedAmountMinorUnits: 70000,
            spentAmountMinorUnits: 35000,
            level: BudgetProgressLevel.normal,
          ),
          BudgetProgress(
            budgetId: 'budget-3',
            categoryId: 'category-3',
            categoryName: 'Shopping',
            allocatedAmountMinorUnits: 5000,
            spentAmountMinorUnits: 1000,
            level: BudgetProgressLevel.normal,
          ),
          BudgetProgress(
            budgetId: 'budget-7',
            categoryId: 'category-9',
            categoryName: 'Uncategorized',
            allocatedAmountMinorUnits: 1000,
            spentAmountMinorUnits: 0,
            level: BudgetProgressLevel.normal,
          ),
          BudgetProgress(
            budgetId: 'budget-5',
            categoryId: 'category-5',
            categoryName: 'Utilities',
            allocatedAmountMinorUnits: 0,
            spentAmountMinorUnits: 0,
            level: BudgetProgressLevel.normal,
          ),
        ]);
      });

      test('honors a per-budget warning share over the default', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {
            'category-1': testAnalyticsCategory(id: 'category-1', name: 'Food'),
            'category-2': testAnalyticsCategory(
              id: 'category-2',
              name: 'Transport',
            ),
          },
          initialBudgets: {
            'budget-lenient': testBudget(
              id: 'budget-lenient',
              allocatedAmountMinorUnits: 100000,
              warningShare: 0.95,
            ),
            'budget-strict': testBudget(
              id: 'budget-strict',
              categoryId: 'category-2',
              allocatedAmountMinorUnits: 100000,
              warningShare: 0.5,
            ),
          },
          initialTransactions: {
            'food': testTransaction(
              id: 'food',
              categoryId: 'category-1',
              amountMinorUnits: 90000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            'transport': testTransaction(
              id: 'transport',
              categoryId: 'category-2',
              amountMinorUnits: 60000,
              timestamp: DateTime.utc(2026, 10, 6),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        // 90% spent: normal against a 95% threshold, warning against the
        // 0.85 default. 60% spent: warning against a 50% threshold.
        expect(dashboard.budgetProgress, const [
          BudgetProgress(
            budgetId: 'budget-strict',
            categoryId: 'category-2',
            categoryName: 'Transport',
            allocatedAmountMinorUnits: 100000,
            spentAmountMinorUnits: 60000,
            level: BudgetProgressLevel.warning,
          ),
          BudgetProgress(
            budgetId: 'budget-lenient',
            categoryId: 'category-1',
            categoryName: 'Food',
            allocatedAmountMinorUnits: 100000,
            spentAmountMinorUnits: 90000,
            level: BudgetProgressLevel.normal,
          ),
        ]);
      });

      test('reports spending against a zero allocation as exceeded', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {'category-1': testCategory()},
          initialBudgets: {
            'budget-1': testBudget(allocatedAmountMinorUnits: 0),
          },
          initialTransactions: {
            'food': testTransaction(
              id: 'food',
              categoryId: 'category-1',
              amountMinorUnits: 5000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.budgetProgress.single.usedRatio, 1);
        expect(dashboard.budgetProgress, const [
          BudgetProgress(
            budgetId: 'budget-1',
            categoryId: 'category-1',
            categoryName: 'Food',
            allocatedAmountMinorUnits: 0,
            spentAmountMinorUnits: 5000,
            level: BudgetProgressLevel.exceeded,
          ),
        ]);
      });

      test('anchors budget windows at the budget start date', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {
            'category-1': testCategory(),
            'category-2': testAnalyticsCategory(
              id: 'category-2',
              name: 'Transport',
            ),
          },
          initialBudgets: {
            'budget-monthly': testBudget(
              id: 'budget-monthly',
              startDate: DateTime.utc(2026, 10, 10),
            ),
            'budget-weekly': testBudget(
              id: 'budget-weekly',
              categoryId: 'category-2',
              period: BudgetPeriod.weekly,
              startDate: DateTime.utc(2026, 10, 12),
            ),
          },
          initialTransactions: {
            'food-anchored': testTransaction(
              id: 'food-anchored',
              categoryId: 'category-1',
              amountMinorUnits: 5000,
              timestamp: DateTime.utc(2026, 10, 12),
            ),
            'food-before': testTransaction(
              id: 'food-before',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            'transport-anchored': testTransaction(
              id: 'transport-anchored',
              categoryId: 'category-2',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 12),
            ),
            'transport-before': testTransaction(
              id: 'transport-before',
              categoryId: 'category-2',
              amountMinorUnits: 4000,
              timestamp: DateTime.utc(2026, 10, 11),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.budgetProgress, const [
          BudgetProgress(
            budgetId: 'budget-monthly',
            categoryId: 'category-1',
            categoryName: 'Food',
            allocatedAmountMinorUnits: 10000,
            spentAmountMinorUnits: 5000,
            level: BudgetProgressLevel.normal,
          ),
          BudgetProgress(
            budgetId: 'budget-weekly',
            categoryId: 'category-2',
            categoryName: 'Transport',
            allocatedAmountMinorUnits: 10000,
            spentAmountMinorUnits: 2000,
            level: BudgetProgressLevel.normal,
          ),
        ]);
      });

      test(
        'uses the first window for a budget starting in the future',
        () async {
          final harness = AnalyticsTestHarness(
            initialCategories: {'category-1': testCategory()},
            initialBudgets: {
              'budget-future': testBudget(
                id: 'budget-future',
                startDate: DateTime.utc(2026, 11),
              ),
            },
            initialTransactions: {
              'oct': testTransaction(
                id: 'oct',
                categoryId: 'category-1',
                amountMinorUnits: 7000,
                timestamp: DateTime.utc(2026, 10, 5),
              ),
              'nov': testTransaction(
                id: 'nov',
                categoryId: 'category-1',
                amountMinorUnits: 4000,
                timestamp: DateTime.utc(2026, 11, 5),
              ),
            },
          );

          final dashboard = await harness.service.loadDashboard(
            period: AnalyticsPeriod.month,
          );

          expect(dashboard.budgetProgress, const [
            BudgetProgress(
              budgetId: 'budget-future',
              categoryId: 'category-1',
              categoryName: 'Food',
              allocatedAmountMinorUnits: 10000,
              spentAmountMinorUnits: 4000,
              level: BudgetProgressLevel.normal,
            ),
          ]);
        },
      );

      test(
        'keeps the anchored window when the next one has not started',
        () async {
          final harness = AnalyticsTestHarness(
            initialCategories: {'category-1': testCategory()},
            initialBudgets: {
              'budget-monthly': testBudget(
                id: 'budget-monthly',
                startDate: DateTime.utc(2026, 9, 20),
              ),
            },
            initialTransactions: {
              'before': testTransaction(
                id: 'before',
                categoryId: 'category-1',
                timestamp: DateTime.utc(2026, 9, 10),
              ),
              'sept': testTransaction(
                id: 'sept',
                categoryId: 'category-1',
                amountMinorUnits: 3000,
                timestamp: DateTime.utc(2026, 9, 25),
              ),
              'oct': testTransaction(
                id: 'oct',
                categoryId: 'category-1',
                amountMinorUnits: 2000,
                timestamp: DateTime.utc(2026, 10, 5),
              ),
            },
          );

          final dashboard = await harness.service.loadDashboard(
            period: AnalyticsPeriod.month,
          );

          expect(dashboard.budgetProgress, const [
            BudgetProgress(
              budgetId: 'budget-monthly',
              categoryId: 'category-1',
              categoryName: 'Food',
              allocatedAmountMinorUnits: 10000,
              spentAmountMinorUnits: 5000,
              level: BudgetProgressLevel.normal,
            ),
          ]);
        },
      );

      test('starts a new window on the anchor day', () async {
        final harness = AnalyticsTestHarness(
          now: () => DateTime.utc(2026, 10, 20),
          initialCategories: {'category-1': testCategory()},
          initialBudgets: {
            'budget-monthly': testBudget(
              id: 'budget-monthly',
              startDate: DateTime.utc(2026, 9, 20),
            ),
          },
          initialTransactions: {
            'yesterday': testTransaction(
              id: 'yesterday',
              categoryId: 'category-1',
              timestamp: DateTime.utc(2026, 10, 19),
            ),
            'today': testTransaction(
              id: 'today',
              categoryId: 'category-1',
              amountMinorUnits: 2500,
              timestamp: DateTime.utc(2026, 10, 20),
            ),
            'tomorrow': testTransaction(
              id: 'tomorrow',
              categoryId: 'category-1',
              amountMinorUnits: 500,
              timestamp: DateTime.utc(2026, 10, 21),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.budgetProgress, const [
          BudgetProgress(
            budgetId: 'budget-monthly',
            categoryId: 'category-1',
            categoryName: 'Food',
            allocatedAmountMinorUnits: 10000,
            spentAmountMinorUnits: 3000,
            level: BudgetProgressLevel.normal,
          ),
        ]);
      });

      test('keeps clamped windows contiguous before the anchor day', () async {
        final harness = AnalyticsTestHarness(
          now: () => DateTime.utc(2026, 3, 29),
          initialCategories: {'category-1': testCategory()},
          initialBudgets: {
            'budget-monthly': testBudget(
              id: 'budget-monthly',
              startDate: DateTime.utc(2026, 1, 31),
            ),
          },
          initialTransactions: {
            'window-start': testTransaction(
              id: 'window-start',
              categoryId: 'category-1',
              amountMinorUnits: 3000,
              timestamp: DateTime.utc(2026, 2, 28),
            ),
            'in-window': testTransaction(
              id: 'in-window',
              categoryId: 'category-1',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 3, 10),
            ),
            'window-end': testTransaction(
              id: 'window-end',
              categoryId: 'category-1',
              timestamp: DateTime.utc(2026, 3, 28),
            ),
            'orphan-day': testTransaction(
              id: 'orphan-day',
              categoryId: 'category-1',
              amountMinorUnits: 500,
              timestamp: DateTime.utc(2026, 3, 29),
            ),
            'next-window': testTransaction(
              id: 'next-window',
              categoryId: 'category-1',
              amountMinorUnits: 700,
              timestamp: DateTime.utc(2026, 3, 31),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.budgetProgress, const [
          BudgetProgress(
            budgetId: 'budget-monthly',
            categoryId: 'category-1',
            categoryName: 'Food',
            allocatedAmountMinorUnits: 10000,
            spentAmountMinorUnits: 6500,
            level: BudgetProgressLevel.normal,
          ),
        ]);
      });

      test('marks the warning and exceeded boundaries inclusively', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {
            'category-1': testCategory(),
            'category-2': testAnalyticsCategory(
              id: 'category-2',
              name: 'Transport',
            ),
          },
          initialBudgets: {
            'budget-warning': testBudget(id: 'budget-warning'),
            'budget-exceeded': testBudget(
              id: 'budget-exceeded',
              categoryId: 'category-2',
            ),
          },
          initialTransactions: {
            'warning': testTransaction(
              id: 'warning',
              categoryId: 'category-1',
              amountMinorUnits: 8500,
              timestamp: DateTime.utc(2026, 10, 5),
            ),
            'exceeded': testTransaction(
              id: 'exceeded',
              categoryId: 'category-2',
              amountMinorUnits: 10000,
              timestamp: DateTime.utc(2026, 10, 6),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.budgetProgress, const [
          BudgetProgress(
            budgetId: 'budget-exceeded',
            categoryId: 'category-2',
            categoryName: 'Transport',
            allocatedAmountMinorUnits: 10000,
            spentAmountMinorUnits: 10000,
            level: BudgetProgressLevel.exceeded,
          ),
          BudgetProgress(
            budgetId: 'budget-warning',
            categoryId: 'category-1',
            categoryName: 'Food',
            allocatedAmountMinorUnits: 10000,
            spentAmountMinorUnits: 8500,
            level: BudgetProgressLevel.warning,
          ),
        ]);
      });

      test('breaks budget order ties by budget id', () async {
        final harness = AnalyticsTestHarness(
          initialCategories: {'category-1': testCategory()},
          initialBudgets: {
            'budget-b': testBudget(id: 'budget-b'),
            'budget-a': testBudget(id: 'budget-a'),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.budgetProgress.map((progress) => progress.budgetId), [
          'budget-a',
          'budget-b',
        ]);
      });

      test('compares the full previous month on the last day', () async {
        final harness = AnalyticsTestHarness(
          now: () => DateTime.utc(2026, 10, 31),
        );

        await harness.service.loadDashboard(period: AnalyticsPeriod.month);

        expect(harness.analyticsRepository.requestedRanges, [
          (DateTime.utc(2026, 10), DateTime.utc(2026, 11)),
          (DateTime.utc(2026, 9), DateTime.utc(2026, 10)),
        ]);
      });
    });

    group('multi-currency aggregation', () {
      test('picks the most common active currency as primary', () async {
        final harness = AnalyticsTestHarness(
          initialAccounts: {
            'account-1': testAccount(),
            'account-2': testAccount(id: 'account-2'),
            'account-3': const Account(
              id: 'account-3',
              name: 'Dollar Wallet',
              type: AccountType.cash,
              currency: 'USD',
              balanceMinorUnits: 100,
            ),
          },
          onSummary: (startUtc, endUtc) =>
              _summary(startUtc: startUtc, endUtc: endUtc),
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.primaryCurrency, 'EGP');
        expect(
          harness.analyticsRepository.requestedCurrencies,
          everyElement('EGP'),
        );
      });

      test('breaks currency ties alphabetically', () async {
        final harness = AnalyticsTestHarness(
          initialAccounts: {
            'account-1': testAccount(),
            'account-2': const Account(
              id: 'account-2',
              name: 'Dollar Wallet',
              type: AccountType.cash,
              currency: 'USD',
              balanceMinorUnits: 100,
            ),
          },
          onSummary: (startUtc, endUtc) =>
              _summary(startUtc: startUtc, endUtc: endUtc),
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.primaryCurrency, 'EGP');
      });

      test('falls back to no filter when every account is archived', () async {
        final harness = AnalyticsTestHarness(
          initialAccounts: {
            'account-1': const Account(
              id: 'account-1',
              name: 'Archived',
              type: AccountType.cash,
              currency: 'EGP',
              balanceMinorUnits: 0,
              archived: true,
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.primaryCurrency, isNull);
        expect(
          harness.analyticsRepository.requestedCurrencies,
          everyElement(isNull),
        );
      });

      test('filters budget spending to the primary currency', () async {
        final harness = AnalyticsTestHarness(
          initialAccounts: {
            'account-1': testAccount(),
            'account-2': const Account(
              id: 'account-2',
              name: 'USD Wallet',
              type: AccountType.cash,
              currency: 'USD',
              balanceMinorUnits: 100,
            ),
          },
          initialCategories: {'category-1': testCategory()},
          initialBudgets: {
            'budget-1': testBudget(allocatedAmountMinorUnits: 5000),
          },
          initialTransactions: {
            'txn-egp': testTransaction(
              id: 'txn-egp',
              timestamp: DateTime.utc(2026, 10, 5),
              amountMinorUnits: 1250,
              categoryId: 'category-1',
            ),
            'txn-usd': testTransaction(
              id: 'txn-usd',
              timestamp: DateTime.utc(2026, 10, 6),
              amountMinorUnits: 999,
              accountId: 'account-2',
              categoryId: 'category-1',
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.primaryCurrency, 'EGP');
        expect(dashboard.budgetProgress, [
          const BudgetProgress(
            budgetId: 'budget-1',
            categoryId: 'category-1',
            categoryName: 'Food',
            allocatedAmountMinorUnits: 5000,
            spentAmountMinorUnits: 1250,
            level: BudgetProgressLevel.normal,
          ),
        ]);
      });
    });
  });
}

AnalyticsSummary _summary({
  required DateTime startUtc,
  required DateTime endUtc,
  int income = 0,
  int expense = 0,
  List<CategoryTotal> categoryTotals = const [],
  List<CategoryTotal> categoryIncomeTotals = const [],
}) {
  return AnalyticsSummary(
    startUtc: startUtc,
    endUtc: endUtc,
    totalIncomeMinorUnits: income,
    totalExpenseMinorUnits: expense,
    categoryExpenseTotals: categoryTotals,
    categoryIncomeTotals: categoryIncomeTotals,
  );
}
