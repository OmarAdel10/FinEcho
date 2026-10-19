import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/analytics/view_model/models/account_total.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_period.dart';
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
          (DateTime.utc(2026, 9), DateTime.utc(2026, 10)),
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
          (DateTime.utc(2026, 10, 5), DateTime.utc(2026, 10, 12)),
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
          (DateTime.utc(2025), DateTime.utc(2026)),
        ]);
        expect(dashboard.startUtc, DateTime.utc(2026));
        expect(dashboard.endUtc, DateTime.utc(2027));
      });

      test('propagates repository failures', () async {
        final harness = AnalyticsTestHarness();
        harness.analyticsRepository.error = Exception('boom');

        await expectLater(
          harness.service.loadDashboard(period: AnalyticsPeriod.month),
          throwsA(isA<Exception>()),
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
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.accountTotals, const [
          AccountTotal(
            accountId: 'account-1',
            name: 'Cash',
            incomeMinorUnits: 20000,
            expenseMinorUnits: 10000,
          ),
          AccountTotal(
            accountId: 'account-2',
            name: 'Bank',
            incomeMinorUnits: 0,
            expenseMinorUnits: 10000,
          ),
          AccountTotal(
            accountId: 'account-9',
            name: 'Unknown account',
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
            incomeMinorUnits: 0,
            expenseMinorUnits: 2000,
          ),
        ]);
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
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 9, 10),
            ),
            'r2': testTransaction(
              id: 'r2',
              categoryId: 'category-1',
              amountMinorUnits: 4530,
              timestamp: DateTime.utc(2026, 10, 10),
            ),
            'r3': testTransaction(
              id: 'r3',
              categoryId: 'category-1',
              amountMinorUnits: 8000,
              timestamp: DateTime.utc(2026, 10, 12),
            ),
            'r4': testTransaction(
              id: 'r4',
              categoryId: 'category-2',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 8, 15),
            ),
            'r5': testTransaction(
              id: 'r5',
              categoryId: 'category-2',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 9, 15),
            ),
            'r6': testTransaction(
              id: 'r6',
              categoryId: 'category-2',
              amountMinorUnits: 2000,
              timestamp: DateTime.utc(2026, 10, 15),
            ),
            'r7': testTransaction(
              id: 'r7',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 7, 10),
            ),
            'r8': testTransaction(
              id: 'r8',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 9, 12),
              type: TransactionType.income,
            ),
            'r9': testTransaction(
              id: 'r9',
              categoryId: 'category-1',
              amountMinorUnits: 4500,
              timestamp: DateTime.utc(2026, 10, 12),
              type: TransactionType.transfer,
            ),
            'r10': testTransaction(
              id: 'r10',
              amountMinorUnits: 6000,
              timestamp: DateTime.utc(2026, 9, 20),
            ),
            'r11': testTransaction(
              id: 'r11',
              amountMinorUnits: 6000,
              timestamp: DateTime.utc(2026, 10, 14),
            ),
          },
        );

        final dashboard = await harness.service.loadDashboard(
          period: AnalyticsPeriod.month,
        );

        expect(dashboard.recurringCharges, [
          RecurringCharge(
            categoryId: 'category-2',
            name: 'Transport',
            amountMinorUnits: 2000,
            monthsSeen: 3,
            lastSeenUtc: DateTime.utc(2026, 10, 15),
          ),
          RecurringCharge(
            categoryId: null,
            name: 'Uncategorized',
            amountMinorUnits: 6000,
            monthsSeen: 2,
            lastSeenUtc: DateTime.utc(2026, 10, 14),
          ),
          RecurringCharge(
            categoryId: 'category-1',
            name: 'Food',
            amountMinorUnits: 4530,
            monthsSeen: 2,
            lastSeenUtc: DateTime.utc(2026, 10, 10),
          ),
        ]);
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
            previousAverageMinorUnits: 3000,
            ratio: 2,
          ),
          CategorySpike(
            categoryId: null,
            name: 'Uncategorized',
            currentExpenseMinorUnits: 4800,
            previousAverageMinorUnits: 3000,
            ratio: 1.6,
          ),
          CategorySpike(
            categoryId: 'category-3',
            name: 'Shopping',
            currentExpenseMinorUnits: 13500,
            previousAverageMinorUnits: 9000,
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

        expect(dashboard.forecast.monthStartUtc, DateTime.utc(2026, 10));
        expect(dashboard.forecast.monthEndUtc, DateTime.utc(2026, 11));
        expect(dashboard.forecast.elapsedDays, 15);
        expect(dashboard.forecast.daysInMonth, 31);
        expect(dashboard.forecast.expenseSoFarMinorUnits, 100000);
        expect(dashboard.forecast.projectedExpenseMinorUnits, 206667);
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
        expect(dashboard.forecast.projectedExpenseMinorUnits, 310000);
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
    });
  });
}

AnalyticsSummary _summary({
  required DateTime startUtc,
  required DateTime endUtc,
  int income = 0,
  int expense = 0,
  List<CategoryTotal> categoryTotals = const [],
}) {
  return AnalyticsSummary(
    startUtc: startUtc,
    endUtc: endUtc,
    totalIncomeMinorUnits: income,
    totalExpenseMinorUnits: expense,
    categoryExpenseTotals: categoryTotals,
  );
}
