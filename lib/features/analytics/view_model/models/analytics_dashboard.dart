import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/features/analytics/view_model/models/account_total.dart';
import 'package:finecho/features/analytics/view_model/models/budget_progress.dart';
import 'package:finecho/features/analytics/view_model/models/category_spike.dart';
import 'package:finecho/features/analytics/view_model/models/monthly_forecast.dart';
import 'package:finecho/features/analytics/view_model/models/recurring_charge.dart';
import 'package:flutter/foundation.dart';

/// Everything the statistics screen renders for one selected period.
@immutable
class AnalyticsDashboard {
  /// Creates an immutable analytics dashboard snapshot.
  const new({
    required this.period,
    required this.startUtc,
    required this.endUtc,
    required this.primaryCurrency,
    required this.totalIncomeMinorUnits,
    required this.totalExpenseMinorUnits,
    required this.netAmountMinorUnits,
    required this.previousExpenseMinorUnits,
    required this.hasPreviousPeriod,
    required this.expenseChangeRatio,
    required this.categoryTotals,
    required this.categoryIncomeTotals,
    required this.accountTotals,
    required this.recurringCharges,
    required this.unusualSpikes,
    required this.forecast,
    required this.budgetProgress,
  });

  /// The selected period.
  final AnalyticsPeriod period;

  /// The inclusive UTC start of the summary range.
  final DateTime startUtc;

  /// The exclusive UTC end of the summary range.
  final DateTime endUtc;

  /// The ISO currency code the monetary totals are denominated in, or `null`
  /// when the user has no active accounts.
  ///
  /// Totals only aggregate accounts that use this currency; amounts in other
  /// currencies are excluded rather than converted.
  final String? primaryCurrency;

  /// Total income in minor units.
  final int totalIncomeMinorUnits;

  /// Total expenses in minor units.
  final int totalExpenseMinorUnits;

  /// Income minus expenses in minor units.
  final int netAmountMinorUnits;

  /// Total expenses of the equivalent previous period in minor units.
  final int previousExpenseMinorUnits;

  /// Whether the previous period range exists, even if it has no spending.
  final bool hasPreviousPeriod;

  /// The expense change versus the previous period, or `null` without history.
  final double? expenseChangeRatio;

  /// Expenses per category, highest first.
  final List<CategoryTotal> categoryTotals;

  /// Income per category, highest first.
  final List<CategoryTotal> categoryIncomeTotals;

  /// Income and expenses per account, highest expense first.
  final List<AccountTotal> accountTotals;

  /// Expenses repeating across months, strongest recurrence first.
  final List<RecurringCharge> recurringCharges;

  /// Categories spending far above their recent average, highest first.
  final List<CategorySpike> unusualSpikes;

  /// The projection for the current calendar month.
  final MonthlyForecast forecast;

  /// Spending against every budget, most severe first.
  final List<BudgetProgress> budgetProgress;
}
