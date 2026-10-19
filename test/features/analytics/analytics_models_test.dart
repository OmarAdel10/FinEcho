import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/features/analytics/view_model/models/account_total.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_dashboard.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_period.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_state.dart';
import 'package:finecho/features/analytics/view_model/models/budget_progress.dart';
import 'package:finecho/features/analytics/view_model/models/category_spike.dart';
import 'package:finecho/features/analytics/view_model/models/monthly_forecast.dart';
import 'package:finecho/features/analytics/view_model/models/recurring_charge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsPeriod', () {
    test('lists the supported periods in order', () {
      expect(AnalyticsPeriod.values, [
        AnalyticsPeriod.week,
        AnalyticsPeriod.month,
        AnalyticsPeriod.year,
      ]);
    });
  });

  group('AnalyticsStatus', () {
    test('lists the lifecycle states in order', () {
      expect(AnalyticsStatus.values, [
        AnalyticsStatus.loading,
        AnalyticsStatus.ready,
        AnalyticsStatus.failure,
      ]);
    });
  });

  group('AnalyticsState', () {
    test('starts on the monthly period while loading', () {
      const state = AnalyticsState();

      expect(state.status, AnalyticsStatus.loading);
      expect(state.period, AnalyticsPeriod.month);
      expect(state.dashboard, isNull);
      expect(state.errorMessage, isNull);
    });

    test('carries a dashboard once ready', () {
      final dashboard = _dashboard();
      final state = AnalyticsState(
        status: AnalyticsStatus.ready,
        dashboard: dashboard,
      );

      expect(state.status, AnalyticsStatus.ready);
      expect(state.dashboard, same(dashboard));
    });
  });

  group('AccountTotal', () {
    test('derives the net amount from income and expenses', () {
      const total = AccountTotal(
        accountId: 'account-1',
        name: 'Cash',
        incomeMinorUnits: 20000,
        expenseMinorUnits: 5000,
      );

      expect(total.netAmountMinorUnits, 15000);
    });

    test('supports value equality', () {
      const total = AccountTotal(
        accountId: 'account-1',
        name: 'Cash',
        incomeMinorUnits: 20000,
        expenseMinorUnits: 5000,
      );
      const same = AccountTotal(
        accountId: 'account-1',
        name: 'Cash',
        incomeMinorUnits: 20000,
        expenseMinorUnits: 5000,
      );
      const different = AccountTotal(
        accountId: 'account-2',
        name: 'Cash',
        incomeMinorUnits: 20000,
        expenseMinorUnits: 5000,
      );

      expect(total, same);
      expect(total, isNot(different));
    });
  });

  group('RecurringCharge', () {
    test('supports value equality', () {
      final charge = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 3,
        lastSeenUtc: DateTime.utc(2026, 10, 10),
      );
      final same = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 3,
        lastSeenUtc: DateTime.utc(2026, 10, 10),
      );
      final different = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 2,
        lastSeenUtc: DateTime.utc(2026, 10, 10),
      );

      expect(charge, same);
      expect(charge, isNot(different));
    });
  });

  group('CategorySpike', () {
    test('supports value equality', () {
      const spike = CategorySpike(
        categoryId: null,
        name: 'Uncategorized',
        currentExpenseMinorUnits: 4800,
        previousAverageMinorUnits: 3000,
        ratio: 1.6,
      );
      const same = CategorySpike(
        categoryId: null,
        name: 'Uncategorized',
        currentExpenseMinorUnits: 4800,
        previousAverageMinorUnits: 3000,
        ratio: 1.6,
      );
      const different = CategorySpike(
        categoryId: null,
        name: 'Uncategorized',
        currentExpenseMinorUnits: 4800,
        previousAverageMinorUnits: 3000,
        ratio: 2,
      );

      expect(spike, same);
      expect(spike, isNot(different));
    });
  });

  group('MonthlyForecast', () {
    test('supports value equality', () {
      final forecast = MonthlyForecast(
        monthStartUtc: DateTime.utc(2026, 10),
        monthEndUtc: DateTime.utc(2026, 11),
        elapsedDays: 15,
        daysInMonth: 31,
        expenseSoFarMinorUnits: 150000,
        projectedExpenseMinorUnits: 310000,
      );
      final same = MonthlyForecast(
        monthStartUtc: DateTime.utc(2026, 10),
        monthEndUtc: DateTime.utc(2026, 11),
        elapsedDays: 15,
        daysInMonth: 31,
        expenseSoFarMinorUnits: 150000,
        projectedExpenseMinorUnits: 310000,
      );
      final different = MonthlyForecast(
        monthStartUtc: DateTime.utc(2026, 10),
        monthEndUtc: DateTime.utc(2026, 11),
        elapsedDays: 15,
        daysInMonth: 31,
        expenseSoFarMinorUnits: 150000,
        projectedExpenseMinorUnits: 206667,
      );

      expect(forecast, same);
      expect(forecast, isNot(different));
    });
  });

  group('BudgetProgressLevel', () {
    test('lists the severity levels in order', () {
      expect(BudgetProgressLevel.values, [
        BudgetProgressLevel.normal,
        BudgetProgressLevel.warning,
        BudgetProgressLevel.exceeded,
      ]);
    });
  });

  group('BudgetProgress', () {
    test('derives the used ratio from spent and allocated amounts', () {
      const progress = BudgetProgress(
        budgetId: 'budget-1',
        categoryId: 'category-1',
        categoryName: 'Food',
        allocatedAmountMinorUnits: 100000,
        spentAmountMinorUnits: 90000,
        level: BudgetProgressLevel.warning,
      );

      expect(progress.usedRatio, 0.9);
    });

    test('reports a zero used ratio for a zero allocation', () {
      const progress = BudgetProgress(
        budgetId: 'budget-1',
        categoryId: 'category-1',
        categoryName: 'Food',
        allocatedAmountMinorUnits: 0,
        spentAmountMinorUnits: 2500,
        level: BudgetProgressLevel.exceeded,
      );

      expect(progress.usedRatio, 0);
    });

    test('supports value equality', () {
      const progress = BudgetProgress(
        budgetId: 'budget-1',
        categoryId: 'category-1',
        categoryName: 'Food',
        allocatedAmountMinorUnits: 100000,
        spentAmountMinorUnits: 90000,
        level: BudgetProgressLevel.warning,
      );
      const same = BudgetProgress(
        budgetId: 'budget-1',
        categoryId: 'category-1',
        categoryName: 'Food',
        allocatedAmountMinorUnits: 100000,
        spentAmountMinorUnits: 90000,
        level: BudgetProgressLevel.warning,
      );
      const different = BudgetProgress(
        budgetId: 'budget-1',
        categoryId: 'category-1',
        categoryName: 'Food',
        allocatedAmountMinorUnits: 100000,
        spentAmountMinorUnits: 90000,
        level: BudgetProgressLevel.exceeded,
      );

      expect(progress, same);
      expect(progress, isNot(different));
    });
  });

  group('AnalyticsDashboard', () {
    test('carries every derived section for the selected period', () {
      final dashboard = _dashboard();

      expect(dashboard.period, AnalyticsPeriod.month);
      expect(dashboard.startUtc, DateTime.utc(2026, 10));
      expect(dashboard.endUtc, DateTime.utc(2026, 11));
      expect(dashboard.totalIncomeMinorUnits, 200000);
      expect(dashboard.totalExpenseMinorUnits, 150000);
      expect(dashboard.netAmountMinorUnits, 50000);
      expect(dashboard.previousExpenseMinorUnits, 100000);
      expect(dashboard.expenseChangeRatio, 0.5);
      expect(dashboard.categoryTotals, hasLength(1));
      expect(dashboard.accountTotals, isEmpty);
      expect(dashboard.recurringCharges, isEmpty);
      expect(dashboard.unusualSpikes, isEmpty);
      expect(dashboard.forecast.elapsedDays, 15);
      expect(dashboard.budgetProgress, isEmpty);
    });
  });

  group('hashCode', () {
    test('matches equal account totals and differs for distinct ones', () {
      const total = AccountTotal(
        accountId: 'account-1',
        name: 'Cash',
        incomeMinorUnits: 20000,
        expenseMinorUnits: 5000,
      );
      const same = AccountTotal(
        accountId: 'account-1',
        name: 'Cash',
        incomeMinorUnits: 20000,
        expenseMinorUnits: 5000,
      );
      const different = AccountTotal(
        accountId: 'account-2',
        name: 'Cash',
        incomeMinorUnits: 20000,
        expenseMinorUnits: 5000,
      );

      expect(total.hashCode, same.hashCode);
      expect(total.hashCode, isNot(different.hashCode));
    });

    test('matches equal recurring charges and differs for distinct ones', () {
      final charge = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 3,
        lastSeenUtc: DateTime.utc(2026, 10, 10),
      );
      final same = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 3,
        lastSeenUtc: DateTime.utc(2026, 10, 10),
      );
      final different = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 2,
        lastSeenUtc: DateTime.utc(2026, 10, 10),
      );

      expect(charge.hashCode, same.hashCode);
      expect(charge.hashCode, isNot(different.hashCode));
    });

    test('matches equal spikes and differs for distinct ones', () {
      const spike = CategorySpike(
        categoryId: null,
        name: 'Uncategorized',
        currentExpenseMinorUnits: 4800,
        previousAverageMinorUnits: 3000,
        ratio: 1.6,
      );
      const same = CategorySpike(
        categoryId: null,
        name: 'Uncategorized',
        currentExpenseMinorUnits: 4800,
        previousAverageMinorUnits: 3000,
        ratio: 1.6,
      );
      const different = CategorySpike(
        categoryId: null,
        name: 'Uncategorized',
        currentExpenseMinorUnits: 4800,
        previousAverageMinorUnits: 3000,
        ratio: 2,
      );

      expect(spike.hashCode, same.hashCode);
      expect(spike.hashCode, isNot(different.hashCode));
    });

    test('matches equal forecasts and differs for distinct ones', () {
      final forecast = MonthlyForecast(
        monthStartUtc: DateTime.utc(2026, 10),
        monthEndUtc: DateTime.utc(2026, 11),
        elapsedDays: 15,
        daysInMonth: 31,
        expenseSoFarMinorUnits: 150000,
        projectedExpenseMinorUnits: 310000,
      );
      final same = MonthlyForecast(
        monthStartUtc: DateTime.utc(2026, 10),
        monthEndUtc: DateTime.utc(2026, 11),
        elapsedDays: 15,
        daysInMonth: 31,
        expenseSoFarMinorUnits: 150000,
        projectedExpenseMinorUnits: 310000,
      );
      final different = MonthlyForecast(
        monthStartUtc: DateTime.utc(2026, 10),
        monthEndUtc: DateTime.utc(2026, 11),
        elapsedDays: 15,
        daysInMonth: 31,
        expenseSoFarMinorUnits: 150000,
        projectedExpenseMinorUnits: 206667,
      );

      expect(forecast.hashCode, same.hashCode);
      expect(forecast.hashCode, isNot(different.hashCode));
    });

    test('matches equal budget progress and differs for distinct ones', () {
      const progress = BudgetProgress(
        budgetId: 'budget-1',
        categoryId: 'category-1',
        categoryName: 'Food',
        allocatedAmountMinorUnits: 100000,
        spentAmountMinorUnits: 90000,
        level: BudgetProgressLevel.warning,
      );
      const same = BudgetProgress(
        budgetId: 'budget-1',
        categoryId: 'category-1',
        categoryName: 'Food',
        allocatedAmountMinorUnits: 100000,
        spentAmountMinorUnits: 90000,
        level: BudgetProgressLevel.warning,
      );
      const different = BudgetProgress(
        budgetId: 'budget-1',
        categoryId: 'category-1',
        categoryName: 'Food',
        allocatedAmountMinorUnits: 100000,
        spentAmountMinorUnits: 90000,
        level: BudgetProgressLevel.exceeded,
      );

      expect(progress.hashCode, same.hashCode);
      expect(progress.hashCode, isNot(different.hashCode));
    });
  });
}

AnalyticsDashboard _dashboard() {
  return AnalyticsDashboard(
    period: AnalyticsPeriod.month,
    startUtc: DateTime.utc(2026, 10),
    endUtc: DateTime.utc(2026, 11),
    totalIncomeMinorUnits: 200000,
    totalExpenseMinorUnits: 150000,
    netAmountMinorUnits: 50000,
    previousExpenseMinorUnits: 100000,
    expenseChangeRatio: 0.5,
    categoryTotals: const [
      CategoryTotal(
        categoryId: 'category-1',
        name: 'Food',
        expenseMinorUnits: 42000,
      ),
    ],
    accountTotals: const [],
    recurringCharges: const [],
    unusualSpikes: const [],
    forecast: MonthlyForecast(
      monthStartUtc: DateTime.utc(2026, 10),
      monthEndUtc: DateTime.utc(2026, 11),
      elapsedDays: 15,
      daysInMonth: 31,
      expenseSoFarMinorUnits: 150000,
      projectedExpenseMinorUnits: 310000,
    ),
    budgetProgress: const [],
  );
}
