import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/features/analytics/view_model/models/account_total.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_dashboard.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_state.dart';
import 'package:finecho/features/analytics/view_model/models/budget_progress.dart';
import 'package:finecho/features/analytics/view_model/models/category_spike.dart';
import 'package:finecho/features/analytics/view_model/models/monthly_forecast.dart';
import 'package:finecho/features/analytics/view_model/models/recurring_charge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      const charge = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 3,
      );
      const same = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 3,
      );
      const different = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 2,
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
        ratio: 1.6,
      );
      const same = CategorySpike(
        categoryId: null,
        name: 'Uncategorized',
        currentExpenseMinorUnits: 4800,
        ratio: 1.6,
      );
      const different = CategorySpike(
        categoryId: null,
        name: 'Uncategorized',
        currentExpenseMinorUnits: 4800,
        ratio: 2,
      );

      expect(spike, same);
      expect(spike, isNot(different));
    });
  });

  group('MonthlyForecast', () {
    test('supports value equality', () {
      const forecast = MonthlyForecast(
        elapsedDays: 15,
        daysInMonth: 31,
        expenseSoFarMinorUnits: 150000,
        projectedExpenseMinorUnits: 310000,
      );
      const same = MonthlyForecast(
        elapsedDays: 15,
        daysInMonth: 31,
        expenseSoFarMinorUnits: 150000,
        projectedExpenseMinorUnits: 310000,
      );
      const different = MonthlyForecast(
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

    test('reports a full used ratio for spending without an allocation', () {
      const progress = BudgetProgress(
        budgetId: 'budget-1',
        categoryId: 'category-1',
        categoryName: 'Food',
        allocatedAmountMinorUnits: 0,
        spentAmountMinorUnits: 2500,
        level: BudgetProgressLevel.exceeded,
      );

      expect(progress.usedRatio, 1);
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
    test('matches equal account totals', () {
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

      expect(total.hashCode, same.hashCode);
    });

    test('matches equal recurring charges', () {
      const charge = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 3,
      );
      const same = RecurringCharge(
        categoryId: 'category-1',
        name: 'Food',
        amountMinorUnits: 4500,
        monthsSeen: 3,
      );

      expect(charge.hashCode, same.hashCode);
    });

    test('matches equal spikes', () {
      const spike = CategorySpike(
        categoryId: null,
        name: 'Uncategorized',
        currentExpenseMinorUnits: 4800,
        ratio: 1.6,
      );
      const same = CategorySpike(
        categoryId: null,
        name: 'Uncategorized',
        currentExpenseMinorUnits: 4800,
        ratio: 1.6,
      );

      expect(spike.hashCode, same.hashCode);
    });

    test('matches equal forecasts', () {
      const forecast = MonthlyForecast(
        elapsedDays: 15,
        daysInMonth: 31,
        expenseSoFarMinorUnits: 150000,
        projectedExpenseMinorUnits: 310000,
      );
      const same = MonthlyForecast(
        elapsedDays: 15,
        daysInMonth: 31,
        expenseSoFarMinorUnits: 150000,
        projectedExpenseMinorUnits: 310000,
      );

      expect(forecast.hashCode, same.hashCode);
    });

    test('matches equal budget progress', () {
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

      expect(progress.hashCode, same.hashCode);
    });

    group('AnalyticsState.copyWith', () {
      test('preserves every field when no argument is given', () {
        final state = AnalyticsState(
          status: AnalyticsStatus.ready,
          period: AnalyticsPeriod.year,
          dashboard: _dashboard(),
          errorMessage: 'previous failure',
        );

        final copy = state.copyWith();

        expect(copy.status, AnalyticsStatus.ready);
        expect(copy.period, AnalyticsPeriod.year);
        expect(copy.dashboard, same(state.dashboard));
        expect(copy.errorMessage, 'previous failure');
      });

      test('keeps the dashboard and error message for a status change', () {
        final state = AnalyticsState(
          status: AnalyticsStatus.ready,
          dashboard: _dashboard(),
          errorMessage: 'previous failure',
        );

        final copy = state.copyWith(status: AnalyticsStatus.failure);

        expect(copy.status, AnalyticsStatus.failure);
        expect(copy.dashboard, same(state.dashboard));
        expect(copy.errorMessage, 'previous failure');
      });

      test('clears the error message when requested', () {
        const state = AnalyticsState(
          status: AnalyticsStatus.failure,
          errorMessage: 'previous failure',
        );

        final copy = state.copyWith(
          status: AnalyticsStatus.loading,
          clearErrorMessage: true,
        );

        expect(copy.errorMessage, isNull);
        expect(copy.status, AnalyticsStatus.loading);
      });
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
    categoryIncomeTotals: const [
      CategoryTotal(
        categoryId: 'category-1',
        name: 'Salary',
        expenseMinorUnits: 0,
        incomeMinorUnits: 200000,
      ),
    ],
    accountTotals: const [],
    recurringCharges: const [],
    unusualSpikes: const [],
    forecast: const MonthlyForecast(
      elapsedDays: 15,
      daysInMonth: 31,
      expenseSoFarMinorUnits: 150000,
      projectedExpenseMinorUnits: 310000,
    ),
    budgetProgress: const [],
  );
}
