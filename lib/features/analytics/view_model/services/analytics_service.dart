import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/analytics_account_total.dart';
import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/category_monthly_expense.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';
import 'package:finecho/core/repositories/contracts/analytics_repository.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/features/analytics/view_model/models/account_total.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_dashboard.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_period.dart';
import 'package:finecho/features/analytics/view_model/models/budget_progress.dart';
import 'package:finecho/features/analytics/view_model/models/category_spike.dart';
import 'package:finecho/features/analytics/view_model/models/monthly_forecast.dart';
import 'package:finecho/features/analytics/view_model/models/recurring_charge.dart';

/// Expenses are grouped into amount buckets of this size for recurrence.
/// Consecutive months required before an expense counts as recurring.
const int _recurringMinimumMonths = 2;

/// The current expense must reach this multiple of the recent average.
const double _spikeRatioThreshold = 1.5;

/// The number of months averaged before the current month.
const int _spikeBaselineMonths = 3;

/// Baseline months required before unusual spending can be flagged.
const int _spikeMinimumBaselineMonths = 2;

/// The spent share of a budget that raises a warning.
const double _budgetWarningShare = 0.85;

const String _uncategorizedLabel = 'Uncategorized';
const String _unknownAccountLabel = 'Unknown account';

/// Derives the statistics dashboard from persisted local history.
class AnalyticsService {
  /// Creates an analytics service backed by the FinEcho repositories.
  ///
  /// All transaction-derived figures come from bounded aggregate queries on
  /// [analytics]; the service never scans the full ledger.
  new({
    required AnalyticsRepository analytics,
    required AccountRepository accounts,
    required BudgetRepository budgets,
    required CategoryRepository categories,
    DateTime Function()? now,
    Duration? localUtcOffset,
  }) : this._(
         analytics,
         accounts,
         budgets,
         categories,
         now ?? DateTime.now,
         localUtcOffset ?? DateTime.now().timeZoneOffset,
       );

  new _(
    this._analytics,
    this._accounts,
    this._budgets,
    this._categories,
    this._now,
    this._localUtcOffset,
  );

  final AnalyticsRepository _analytics;
  final AccountRepository _accounts;
  final BudgetRepository _budgets;
  final CategoryRepository _categories;
  final DateTime Function() _now;

  /// How far east of UTC the device's local calendar runs.
  ///
  /// Calendar boundaries are derived from the local wall clock and converted
  /// back to UTC with this offset, so tests can pin the view while production
  /// follows the device zone.
  final Duration _localUtcOffset;

  /// Derives the dashboard for [period] from current local history.
  ///
  /// Calendar ranges follow the device's local calendar and are converted to
  /// UTC to match the stored transaction timestamps, so a user east of UTC
  /// does not see the previous month for the first hours of a new local
  /// month.
  /// Aggregates assume every account shares one display currency; totals are
  /// summed in minor units without conversion.
  Future<AnalyticsDashboard> loadDashboard({
    required AnalyticsPeriod period,
  }) async {
    final nowUtc = _now().toUtc();
    final (startUtc, endUtc) = _rangeFor(period, nowUtc, _localUtcOffset);
    final (previousStartUtc, previousEndUtc) = _previousRangeFor(
      period,
      nowUtc,
      _localUtcOffset,
    );
    final previousComparisonEndUtc = _previousComparisonEnd(
      startUtc: startUtc,
      nowUtc: nowUtc,
      previousStartUtc: previousStartUtc,
      previousEndUtc: previousEndUtc,
    );
    final hasPreviousComparison = previousComparisonEndUtc.isAfter(
      previousStartUtc,
    );

    final (summary, previousSummary, accounts, budgets, categories) = await (
      _analytics.summaryForRange(startUtc: startUtc, endUtc: endUtc),
      hasPreviousComparison
          ? _analytics.summaryForRange(
              startUtc: previousStartUtc,
              endUtc: previousComparisonEndUtc,
            )
          : Future<AnalyticsSummary>.value(
              AnalyticsSummary(
                startUtc: previousStartUtc,
                endUtc: previousEndUtc,
                totalIncomeMinorUnits: 0,
                totalExpenseMinorUnits: 0,
                categoryExpenseTotals: const [],
                categoryIncomeTotals: const [],
              ),
            ),
      _accounts.list(),
      _budgets.list(),
      _categories.list(),
    ).wait;

    final accountsById = <String, Account>{
      for (final account in accounts) account.id: account,
    };
    final categoriesById = <String, Category>{
      for (final category in categories) category.id: category,
    };

    final previousExpense = previousSummary.totalExpenseMinorUnits;
    final totalExpense = summary.totalExpenseMinorUnits;
    final expenseChangeRatio = previousExpense > 0
        ? (totalExpense - previousExpense) / previousExpense
        : null;

    final monthStartUtc = DateTime.utc(nowUtc.year, nowUtc.month);
    final monthEndUtc = DateTime.utc(nowUtc.year, nowUtc.month + 1);
    final recurringWindowStartUtc = DateTime.utc(nowUtc.year, nowUtc.month - 2);
    final spikeBaselineStartUtc = DateTime.utc(
      nowUtc.year,
      nowUtc.month - _spikeBaselineMonths,
    );

    final (
      accountActivityTotals,
      recurringWindowExpenses,
      monthlyCategoryExpenses,
      monthCategoryExpenses,
    ) = await (
      _analytics.accountTotalsForRange(startUtc: startUtc, endUtc: endUtc),
      _analytics.expenseTransactionsForRange(
        startUtc: recurringWindowStartUtc,
        endUtc: monthEndUtc,
      ),
      _analytics.expenseMonthlyTotalsByCategory(
        startUtc: spikeBaselineStartUtc,
        endUtc: monthEndUtc,
      ),
      _analytics.expenseTotalsByCategoryForRange(
        startUtc: monthStartUtc,
        endUtc: monthEndUtc,
      ),
    ).wait;

    final monthExpenseTotal = monthCategoryExpenses.fold<int>(
      0,
      (total, entry) => total + entry.totalMinorUnits,
    );
    final spentByBudgetId = await _spentByBudgetId(budgets, nowUtc);

    return AnalyticsDashboard(
      period: period,
      startUtc: startUtc,
      endUtc: endUtc,
      totalIncomeMinorUnits: summary.totalIncomeMinorUnits,
      totalExpenseMinorUnits: totalExpense,
      netAmountMinorUnits: summary.netAmountMinorUnits,
      previousExpenseMinorUnits: previousExpense,
      expenseChangeRatio: expenseChangeRatio,
      categoryTotals: summary.categoryExpenseTotals,
      categoryIncomeTotals: summary.categoryIncomeTotals,
      accountTotals: _accountTotals(accountActivityTotals, accountsById),
      recurringCharges: _recurringCharges(recurringWindowExpenses, nowUtc),
      unusualSpikes: _unusualSpikes(
        monthlyCategoryExpenses,
        categoriesById,
        nowUtc,
      ),
      forecast: _forecast(monthExpenseTotal, nowUtc),
      budgetProgress: _budgetProgress(budgets, categoriesById, spentByBudgetId),
    );
  }

  static (DateTime, DateTime) _rangeFor(
    AnalyticsPeriod period,
    DateTime nowUtc,
    Duration localUtcOffset,
  ) {
    final nowLocal = nowUtc.add(localUtcOffset);
    switch (period) {
      case AnalyticsPeriod.week:
        final start = _startOfWeek(nowLocal);
        return (
          start.subtract(localUtcOffset),
          start.add(const Duration(days: 7)).subtract(localUtcOffset),
        );
      case AnalyticsPeriod.month:
        return (
          DateTime.utc(nowLocal.year, nowLocal.month).subtract(localUtcOffset),
          DateTime.utc(
            nowLocal.year,
            nowLocal.month + 1,
          ).subtract(localUtcOffset),
        );
      case AnalyticsPeriod.year:
        return (
          DateTime.utc(nowLocal.year).subtract(localUtcOffset),
          DateTime.utc(nowLocal.year + 1).subtract(localUtcOffset),
        );
    }
  }

  static (DateTime, DateTime) _previousRangeFor(
    AnalyticsPeriod period,
    DateTime nowUtc,
    Duration localUtcOffset,
  ) {
    final current = _rangeFor(period, nowUtc, localUtcOffset);
    switch (period) {
      case AnalyticsPeriod.week:
        return (current.$1.subtract(const Duration(days: 7)), current.$1);
      case AnalyticsPeriod.month:
        final localStart = current.$1.add(localUtcOffset);
        return (
          DateTime.utc(
            localStart.year,
            localStart.month - 1,
          ).subtract(localUtcOffset),
          current.$1,
        );
      case AnalyticsPeriod.year:
        final localStart = current.$1.add(localUtcOffset);
        return (
          DateTime.utc(localStart.year - 1).subtract(localUtcOffset),
          current.$1,
        );
    }
  }

  /// Compares like for like: the previous period runs for the same elapsed
  /// duration as the current period, so a partial current period is never
  /// measured against a complete previous one.
  static DateTime _previousComparisonEnd({
    required DateTime startUtc,
    required DateTime nowUtc,
    required DateTime previousStartUtc,
    required DateTime previousEndUtc,
  }) {
    final comparisonEnd = previousStartUtc.add(nowUtc.difference(startUtc));
    return comparisonEnd.isAfter(previousEndUtc)
        ? previousEndUtc
        : comparisonEnd;
  }

  static DateTime _startOfWeek(DateTime nowLocal) {
    final date = DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  static String _categoryName(
    String? categoryId,
    Map<String, Category> categoriesById,
  ) {
    if (categoryId == null) {
      return _uncategorizedLabel;
    }
    return categoriesById[categoryId]?.name ?? _uncategorizedLabel;
  }

  static List<AccountTotal> _accountTotals(
    List<AnalyticsAccountTotal> activityTotals,
    Map<String, Account> accountsById,
  ) {
    final totals = <AccountTotal>[];
    for (final activityTotal in activityTotals) {
      totals.add(
        AccountTotal(
          accountId: activityTotal.accountId,
          name:
              accountsById[activityTotal.accountId]?.name ??
              _unknownAccountLabel,
          incomeMinorUnits: activityTotal.incomeMinorUnits,
          expenseMinorUnits: activityTotal.expenseMinorUnits,
        ),
      );
    }
    totals.sort((a, b) {
      final byExpense = b.expenseMinorUnits.compareTo(a.expenseMinorUnits);
      if (byExpense != 0) {
        return byExpense;
      }
      final byIncome = b.incomeMinorUnits.compareTo(a.incomeMinorUnits);
      if (byIncome != 0) {
        return byIncome;
      }
      final byName = a.name.compareTo(b.name);
      if (byName != 0) {
        return byName;
      }
      return a.accountId.compareTo(b.accountId);
    });
    return totals;
  }

  /// [expenses] are the bounded expense transactions of the recurrence
  /// window, ordered or not; the repository guarantees the window and type.
  ///
  /// Charges are identified by their payee, so transactions without a payee
  /// cannot be attributed to a merchant and never count as recurring.
  static List<RecurringCharge> _recurringCharges(
    List<Transaction> expenses,
    DateTime nowUtc,
  ) {
    final candidates =
        expenses
            .where(
              (transaction) =>
                  transaction.type == TransactionType.expense &&
                  (transaction.payee?.trim().isNotEmpty ?? false),
            )
            .toList()
          ..sort((a, b) {
            final byTimestamp = a.timestamp.compareTo(b.timestamp);
            if (byTimestamp != 0) {
              return byTimestamp;
            }
            return a.amountMinorUnits.compareTo(b.amountMinorUnits);
          });

    final monthsByPayee = <String, Set<int>>{};
    final latestByPayee = <String, Transaction>{};
    for (final transaction in candidates) {
      final key = transaction.payee!.trim().toLowerCase();
      latestByPayee[key] = transaction;
      final timestamp = transaction.timestamp.toUtc();
      monthsByPayee
          .putIfAbsent(key, () => <int>{})
          .add(timestamp.year * 12 + timestamp.month);
    }

    final currentMonth = nowUtc.year * 12 + nowUtc.month;
    final charges = <RecurringCharge>[];
    for (final entry in latestByPayee.entries) {
      final months = monthsByPayee[entry.key]!;
      final latestMonth = months.reduce((a, b) => a > b ? a : b);
      final monthsSeen = _consecutiveMonthRun(months);
      if (latestMonth < currentMonth || monthsSeen < _recurringMinimumMonths) {
        continue;
      }
      final transaction = entry.value;
      charges.add(
        RecurringCharge(
          categoryId: transaction.categoryId,
          name: transaction.payee!.trim(),
          amountMinorUnits: transaction.amountMinorUnits,
          monthsSeen: monthsSeen,
        ),
      );
    }
    charges.sort((a, b) {
      final byMonths = b.monthsSeen.compareTo(a.monthsSeen);
      if (byMonths != 0) {
        return byMonths;
      }
      final byAmount = b.amountMinorUnits.compareTo(a.amountMinorUnits);
      if (byAmount != 0) {
        return byAmount;
      }
      final byName = a.name.compareTo(b.name);
      if (byName != 0) {
        return byName;
      }
      return (a.categoryId ?? '').compareTo(b.categoryId ?? '');
    });
    return charges;
  }

  /// The longest run of consecutive calendar months in [months].
  static int _consecutiveMonthRun(Set<int> months) {
    if (months.isEmpty) {
      return 0;
    }
    final sorted = months.toList()..sort();
    var longest = 1;
    var current = 1;
    for (var index = 1; index < sorted.length; index++) {
      if (sorted[index] == sorted[index - 1] + 1) {
        current += 1;
        if (current > longest) {
          longest = current;
        }
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static List<CategorySpike> _unusualSpikes(
    List<CategoryMonthlyExpense> monthlyExpenses,
    Map<String, Category> categoriesById,
    DateTime nowUtc,
  ) {
    final currentMonth = nowUtc.year * 12 + nowUtc.month;
    final baselineStartMonth =
        nowUtc.year * 12 + nowUtc.month - _spikeBaselineMonths;

    final currentTotals = <String?, int>{};
    final baselineTotals = <String?, int>{};
    final baselineMonths = <String?, Set<int>>{};
    for (final monthlyExpense in monthlyExpenses) {
      final categoryId = monthlyExpense.categoryId;
      if (monthlyExpense.monthUtc == currentMonth) {
        currentTotals.update(
          categoryId,
          (value) => value + monthlyExpense.totalMinorUnits,
          ifAbsent: () => monthlyExpense.totalMinorUnits,
        );
      } else if (monthlyExpense.monthUtc >= baselineStartMonth &&
          monthlyExpense.monthUtc < currentMonth) {
        baselineTotals.update(
          categoryId,
          (value) => value + monthlyExpense.totalMinorUnits,
          ifAbsent: () => monthlyExpense.totalMinorUnits,
        );
        baselineMonths
            .putIfAbsent(categoryId, () => <int>{})
            .add(monthlyExpense.monthUtc);
      }
    }

    final spikes = <CategorySpike>[];
    for (final entry in currentTotals.entries) {
      final baselineMonthCount = baselineMonths[entry.key]?.length ?? 0;
      if (baselineMonthCount < _spikeMinimumBaselineMonths) {
        continue;
      }
      final average = baselineTotals[entry.key]! / baselineMonthCount;
      if (average <= 0 || entry.value < average * _spikeRatioThreshold) {
        continue;
      }
      spikes.add(
        CategorySpike(
          categoryId: entry.key,
          name: _categoryName(entry.key, categoriesById),
          currentExpenseMinorUnits: entry.value,
          ratio: entry.value / average,
        ),
      );
    }
    spikes.sort((a, b) {
      final byRatio = b.ratio.compareTo(a.ratio);
      if (byRatio != 0) {
        return byRatio;
      }
      final byCurrent = b.currentExpenseMinorUnits.compareTo(
        a.currentExpenseMinorUnits,
      );
      if (byCurrent != 0) {
        return byCurrent;
      }
      return (a.categoryId ?? '').compareTo(b.categoryId ?? '');
    });
    return spikes;
  }

  static MonthlyForecast _forecast(
    int monthExpenseMinorUnits,
    DateTime nowUtc,
  ) {
    final monthStart = DateTime.utc(nowUtc.year, nowUtc.month);
    final expenseSoFar = monthExpenseMinorUnits;
    final elapsedDays = nowUtc.day;
    final daysInMonth = DateTime.utc(nowUtc.year, nowUtc.month + 1, 0).day;
    final elapsedFraction =
        nowUtc.difference(monthStart).inMicroseconds /
        Duration.microsecondsPerDay;
    final denominator = elapsedFraction < 1 ? 1.0 : elapsedFraction;
    return MonthlyForecast(
      elapsedDays: elapsedDays,
      daysInMonth: daysInMonth,
      expenseSoFarMinorUnits: expenseSoFar,
      projectedExpenseMinorUnits: elapsedFraction > 0
          ? (expenseSoFar * daysInMonth / denominator).round()
          : expenseSoFar,
    );
  }

  /// Summed spend per budget id from bounded per-window category queries.
  ///
  /// Budgets that share a window reuse the same query result, so the number
  /// of queries follows distinct windows rather than budget count.
  Future<Map<String, int>> _spentByBudgetId(
    List<Budget> budgets,
    DateTime nowUtc,
  ) async {
    if (budgets.isEmpty) {
      return const <String, int>{};
    }
    final totalsByWindow = <(DateTime, DateTime), Map<String, int>>{};
    for (final budget in budgets) {
      final window = _budgetWindow(budget, nowUtc);
      if (totalsByWindow.containsKey(window)) {
        continue;
      }
      final categoryTotals = await _analytics.expenseTotalsByCategoryForRange(
        startUtc: window.$1,
        endUtc: window.$2,
      );
      totalsByWindow[window] = {
        for (final entry in categoryTotals)
          if (entry.categoryId != null)
            entry.categoryId!: entry.totalMinorUnits,
      };
    }
    return {
      for (final budget in budgets)
        budget.id:
            totalsByWindow[_budgetWindow(budget, nowUtc)]![budget.categoryId] ??
            0,
    };
  }

  static List<BudgetProgress> _budgetProgress(
    List<Budget> budgets,
    Map<String, Category> categoriesById,
    Map<String, int> spentByBudgetId,
  ) {
    if (budgets.isEmpty) {
      return const <BudgetProgress>[];
    }

    final progress = <BudgetProgress>[];
    for (final budget in budgets) {
      final spent = spentByBudgetId[budget.id] ?? 0;

      final allocated = budget.allocatedAmountMinorUnits;
      final ratio = allocated > 0 ? spent / allocated : 0.0;
      final BudgetProgressLevel level;
      if ((allocated <= 0 && spent > 0) || ratio >= 1) {
        level = BudgetProgressLevel.exceeded;
      } else if (ratio >= _budgetWarningShare) {
        level = BudgetProgressLevel.warning;
      } else {
        level = BudgetProgressLevel.normal;
      }

      progress.add(
        BudgetProgress(
          budgetId: budget.id,
          categoryId: budget.categoryId,
          categoryName: _categoryName(budget.categoryId, categoriesById),
          allocatedAmountMinorUnits: allocated,
          spentAmountMinorUnits: spent,
          level: level,
        ),
      );
    }
    progress.sort((a, b) {
      final byLevel = b.level.index.compareTo(a.level.index);
      if (byLevel != 0) {
        return byLevel;
      }
      final byRatio = b.usedRatio.compareTo(a.usedRatio);
      if (byRatio != 0) {
        return byRatio;
      }
      final byName = a.categoryName.compareTo(b.categoryName);
      if (byName != 0) {
        return byName;
      }
      return a.budgetId.compareTo(b.budgetId);
    });
    return progress;
  }

  /// The budget window for [nowUtc], anchored to the first period that started
  /// at [Budget.startDate].
  ///
  /// When [nowUtc] precedes the anchor, the first window is returned.
  static (DateTime, DateTime) _budgetWindow(Budget budget, DateTime nowUtc) {
    final anchor = budget.startDate.toUtc();
    switch (budget.period) {
      case BudgetPeriod.daily:
        final start = nowUtc.isBefore(anchor)
            ? anchor
            : anchor.add(Duration(days: nowUtc.difference(anchor).inDays));
        return (start, start.add(const Duration(days: 1)));
      case BudgetPeriod.weekly:
        final start = nowUtc.isBefore(anchor)
            ? anchor
            : anchor.add(
                Duration(days: nowUtc.difference(anchor).inDays ~/ 7 * 7),
              );
        return (start, start.add(const Duration(days: 7)));
      case BudgetPeriod.monthly:
        return _monthAnchoredWindow(anchor, nowUtc, months: 1);
      case BudgetPeriod.yearly:
        return _monthAnchoredWindow(anchor, nowUtc, months: 12);
    }
  }

  /// Returns the month-based window containing [nowUtc], derived from the same
  /// anchor sequence so clamped months never leave a gap before the next
  /// anchor day.
  static (DateTime, DateTime) _monthAnchoredWindow(
    DateTime anchor,
    DateTime nowUtc, {
    required int months,
  }) {
    if (nowUtc.isBefore(anchor)) {
      return (anchor, _addMonths(anchor, months));
    }
    final elapsedMonths =
        (nowUtc.year - anchor.year) * 12 + nowUtc.month - anchor.month;
    var elapsedPeriods = elapsedMonths ~/ months * months;
    if (_addMonths(anchor, elapsedPeriods).isAfter(nowUtc)) {
      elapsedPeriods -= months;
    }
    return (
      _addMonths(anchor, elapsedPeriods),
      _addMonths(anchor, elapsedPeriods + months),
    );
  }

  /// Adds [months] to [start], clamping the day to the target month length.
  ///
  /// [months] must not be negative; callers only move forward from an anchor.
  static DateTime _addMonths(DateTime start, int months) {
    assert(months >= 0, 'months must not be negative');
    final zeroBasedMonth = start.month - 1 + months;
    final targetYear = start.year + zeroBasedMonth ~/ 12;
    final targetMonth = zeroBasedMonth % 12 + 1;
    final lastDay = DateTime.utc(targetYear, targetMonth + 1, 0).day;
    final day = start.day > lastDay ? lastDay : start.day;
    return DateTime.utc(
      targetYear,
      targetMonth,
      day,
      start.hour,
      start.minute,
      start.second,
      start.millisecond,
      start.microsecond,
    );
  }
}
