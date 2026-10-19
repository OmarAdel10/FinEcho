import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';
import 'package:finecho/core/repositories/contracts/analytics_repository.dart';
import 'package:finecho/core/repositories/contracts/budget_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';
import 'package:finecho/features/analytics/view_model/models/account_total.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_dashboard.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_period.dart';
import 'package:finecho/features/analytics/view_model/models/budget_progress.dart';
import 'package:finecho/features/analytics/view_model/models/category_spike.dart';
import 'package:finecho/features/analytics/view_model/models/monthly_forecast.dart';
import 'package:finecho/features/analytics/view_model/models/recurring_charge.dart';

/// Expenses are grouped into amount buckets of this size for recurrence.
const int _recurringAmountBucketMinorUnits = 50;

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
  const new({
    required AnalyticsRepository analytics,
    required TransactionRepository transactions,
    required AccountRepository accounts,
    required BudgetRepository budgets,
    required CategoryRepository categories,
    DateTime Function()? now,
  }) : this._(
         analytics,
         transactions,
         accounts,
         budgets,
         categories,
         now ?? DateTime.now,
       );

  const new _(
    this._analytics,
    this._transactions,
    this._accounts,
    this._budgets,
    this._categories,
    this._now,
  );

  final AnalyticsRepository _analytics;
  final TransactionRepository _transactions;
  final AccountRepository _accounts;
  final BudgetRepository _budgets;
  final CategoryRepository _categories;
  final DateTime Function() _now;

  /// Derives the dashboard for [period] from current local history.
  ///
  /// Aggregates assume every account shares one display currency; totals are
  /// summed in minor units without conversion.
  Future<AnalyticsDashboard> loadDashboard({
    required AnalyticsPeriod period,
  }) async {
    final nowUtc = _now().toUtc();
    final (startUtc, endUtc) = _rangeFor(period, nowUtc);
    final (previousStartUtc, previousEndUtc) = _previousRangeFor(
      period,
      nowUtc,
    );
    final previousComparisonEndUtc = _previousComparisonEnd(
      startUtc: startUtc,
      nowUtc: nowUtc,
      previousStartUtc: previousStartUtc,
      previousEndUtc: previousEndUtc,
    );

    final (
      summary,
      previousSummary,
      transactions,
      accounts,
      budgets,
      categories,
    ) = await (
      _analytics.summaryForRange(startUtc: startUtc, endUtc: endUtc),
      _analytics.summaryForRange(
        startUtc: previousStartUtc,
        endUtc: previousComparisonEndUtc,
      ),
      _transactions.list(),
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
      accountTotals: _accountTotals(
        transactions,
        accountsById,
        startUtc,
        endUtc,
      ),
      recurringCharges: _recurringCharges(transactions, categoriesById, nowUtc),
      unusualSpikes: _unusualSpikes(transactions, categoriesById, nowUtc),
      forecast: _forecast(transactions, nowUtc),
      budgetProgress: _budgetProgress(
        transactions,
        budgets,
        categoriesById,
        nowUtc,
      ),
    );
  }

  static (DateTime, DateTime) _rangeFor(
    AnalyticsPeriod period,
    DateTime nowUtc,
  ) {
    switch (period) {
      case AnalyticsPeriod.week:
        final start = _startOfWeek(nowUtc);
        return (start, start.add(const Duration(days: 7)));
      case AnalyticsPeriod.month:
        return (
          DateTime.utc(nowUtc.year, nowUtc.month),
          DateTime.utc(nowUtc.year, nowUtc.month + 1),
        );
      case AnalyticsPeriod.year:
        return (DateTime.utc(nowUtc.year), DateTime.utc(nowUtc.year + 1));
    }
  }

  static (DateTime, DateTime) _previousRangeFor(
    AnalyticsPeriod period,
    DateTime nowUtc,
  ) {
    switch (period) {
      case AnalyticsPeriod.week:
        final start = _startOfWeek(nowUtc);
        return (start.subtract(const Duration(days: 7)), start);
      case AnalyticsPeriod.month:
        return (
          DateTime.utc(nowUtc.year, nowUtc.month - 1),
          DateTime.utc(nowUtc.year, nowUtc.month),
        );
      case AnalyticsPeriod.year:
        return (DateTime.utc(nowUtc.year - 1), DateTime.utc(nowUtc.year));
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

  static DateTime _startOfWeek(DateTime nowUtc) {
    final date = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  static bool _isWithin(
    Transaction transaction,
    DateTime startUtc,
    DateTime endUtc,
  ) {
    final timestamp = transaction.timestamp.toUtc();
    return !timestamp.isBefore(startUtc) && timestamp.isBefore(endUtc);
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
    List<Transaction> transactions,
    Map<String, Account> accountsById,
    DateTime startUtc,
    DateTime endUtc,
  ) {
    final incomeByAccount = <String, int>{};
    final expenseByAccount = <String, int>{};
    for (final transaction in transactions) {
      if (!_isWithin(transaction, startUtc, endUtc)) {
        continue;
      }
      switch (transaction.type) {
        case TransactionType.income:
          incomeByAccount.update(
            transaction.accountId,
            (value) => value + transaction.amountMinorUnits,
            ifAbsent: () => transaction.amountMinorUnits,
          );
        case TransactionType.expense:
          expenseByAccount.update(
            transaction.accountId,
            (value) => value + transaction.amountMinorUnits,
            ifAbsent: () => transaction.amountMinorUnits,
          );
        case TransactionType.transfer:
          break;
      }
    }

    final totals = <AccountTotal>[];
    final accountIds = <String>{
      ...incomeByAccount.keys,
      ...expenseByAccount.keys,
    };
    for (final accountId in accountIds) {
      totals.add(
        AccountTotal(
          accountId: accountId,
          name: accountsById[accountId]?.name ?? _unknownAccountLabel,
          incomeMinorUnits: incomeByAccount[accountId] ?? 0,
          expenseMinorUnits: expenseByAccount[accountId] ?? 0,
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

  static List<RecurringCharge> _recurringCharges(
    List<Transaction> transactions,
    Map<String, Category> categoriesById,
    DateTime nowUtc,
  ) {
    final windowStart = DateTime.utc(nowUtc.year, nowUtc.month - 2);
    final windowEnd = DateTime.utc(nowUtc.year, nowUtc.month + 1);
    final candidates =
        transactions
            .where(
              (transaction) =>
                  transaction.type == TransactionType.expense &&
                  _isWithin(transaction, windowStart, windowEnd),
            )
            .toList()
          ..sort((a, b) {
            final byTimestamp = a.timestamp.compareTo(b.timestamp);
            if (byTimestamp != 0) {
              return byTimestamp;
            }
            return a.amountMinorUnits.compareTo(b.amountMinorUnits);
          });

    final monthsByGroup = <String, Set<int>>{};
    final latestByGroup = <String, Transaction>{};
    for (final transaction in candidates) {
      final key =
          '${transaction.categoryId ?? ''}|'
          '${_amountBucket(transaction.amountMinorUnits)}';
      latestByGroup[key] = transaction;
      final timestamp = transaction.timestamp.toUtc();
      monthsByGroup
          .putIfAbsent(key, () => <int>{})
          .add(timestamp.year * 12 + timestamp.month);
    }

    final charges = <RecurringCharge>[];
    for (final entry in latestByGroup.entries) {
      final monthsSeen = _consecutiveMonthRun(monthsByGroup[entry.key]!);
      if (monthsSeen < _recurringMinimumMonths) {
        continue;
      }
      final transaction = entry.value;
      charges.add(
        RecurringCharge(
          categoryId: transaction.categoryId,
          name: _categoryName(transaction.categoryId, categoriesById),
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

  static int _amountBucket(int amountMinorUnits) {
    return (amountMinorUnits + _recurringAmountBucketMinorUnits ~/ 2) ~/
        _recurringAmountBucketMinorUnits *
        _recurringAmountBucketMinorUnits;
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
    List<Transaction> transactions,
    Map<String, Category> categoriesById,
    DateTime nowUtc,
  ) {
    final currentStart = DateTime.utc(nowUtc.year, nowUtc.month);
    final currentEnd = DateTime.utc(nowUtc.year, nowUtc.month + 1);
    final baselineStart = DateTime.utc(
      nowUtc.year,
      nowUtc.month - _spikeBaselineMonths,
    );

    final currentTotals = <String?, int>{};
    final baselineTotals = <String?, int>{};
    final baselineMonths = <String?, Set<int>>{};
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }
      if (_isWithin(transaction, currentStart, currentEnd)) {
        currentTotals.update(
          transaction.categoryId,
          (value) => value + transaction.amountMinorUnits,
          ifAbsent: () => transaction.amountMinorUnits,
        );
      } else if (_isWithin(transaction, baselineStart, currentStart)) {
        baselineTotals.update(
          transaction.categoryId,
          (value) => value + transaction.amountMinorUnits,
          ifAbsent: () => transaction.amountMinorUnits,
        );
        final timestamp = transaction.timestamp.toUtc();
        baselineMonths
            .putIfAbsent(transaction.categoryId, () => <int>{})
            .add(timestamp.year * 12 + timestamp.month);
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
    List<Transaction> transactions,
    DateTime nowUtc,
  ) {
    final monthStart = DateTime.utc(nowUtc.year, nowUtc.month);
    final monthEnd = DateTime.utc(nowUtc.year, nowUtc.month + 1);
    var expenseSoFar = 0;
    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense ||
          !_isWithin(transaction, monthStart, monthEnd)) {
        continue;
      }
      expenseSoFar += transaction.amountMinorUnits;
    }
    final elapsedDays = nowUtc.day;
    final daysInMonth = DateTime.utc(nowUtc.year, nowUtc.month + 1, 0).day;
    final elapsedFraction =
        nowUtc.difference(monthStart).inMicroseconds /
        Duration.microsecondsPerDay;
    return MonthlyForecast(
      elapsedDays: elapsedDays,
      daysInMonth: daysInMonth,
      expenseSoFarMinorUnits: expenseSoFar,
      projectedExpenseMinorUnits: elapsedFraction > 0
          ? (expenseSoFar * daysInMonth / elapsedFraction).round()
          : expenseSoFar,
    );
  }

  static List<BudgetProgress> _budgetProgress(
    List<Transaction> transactions,
    List<Budget> budgets,
    Map<String, Category> categoriesById,
    DateTime nowUtc,
  ) {
    if (budgets.isEmpty) {
      return const <BudgetProgress>[];
    }

    final windows = [
      for (final budget in budgets) _budgetWindow(budget, nowUtc),
    ];
    var windowStartUtc = windows.first.$1;
    var windowEndUtc = windows.first.$2;
    for (final (startUtc, endUtc) in windows.skip(1)) {
      if (startUtc.isBefore(windowStartUtc)) {
        windowStartUtc = startUtc;
      }
      if (endUtc.isAfter(windowEndUtc)) {
        windowEndUtc = endUtc;
      }
    }

    final expensesByCategory = <String, List<Transaction>>{};
    for (final transaction in transactions) {
      final categoryId = transaction.categoryId;
      if (transaction.type != TransactionType.expense ||
          categoryId == null ||
          !_isWithin(transaction, windowStartUtc, windowEndUtc)) {
        continue;
      }
      expensesByCategory
          .putIfAbsent(categoryId, () => <Transaction>[])
          .add(transaction);
    }

    final progress = <BudgetProgress>[];
    for (var index = 0; index < budgets.length; index++) {
      final budget = budgets[index];
      final (startUtc, endUtc) = windows[index];
      var spent = 0;
      for (final transaction
          in expensesByCategory[budget.categoryId] ?? const <Transaction>[]) {
        if (!_isWithin(transaction, startUtc, endUtc)) {
          continue;
        }
        spent += transaction.amountMinorUnits;
      }

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
    if (nowUtc.isBefore(anchor)) {
      return (anchor, _addBudgetPeriod(anchor, budget.period));
    }
    final DateTime start;
    switch (budget.period) {
      case BudgetPeriod.daily:
        start = anchor.add(Duration(days: nowUtc.difference(anchor).inDays));
      case BudgetPeriod.weekly:
        start = anchor.add(
          Duration(days: nowUtc.difference(anchor).inDays ~/ 7 * 7),
        );
      case BudgetPeriod.monthly:
        start = _monthAnchoredStart(anchor, nowUtc, months: 1);
      case BudgetPeriod.yearly:
        start = _monthAnchoredStart(anchor, nowUtc, months: 12);
    }
    return (start, _addBudgetPeriod(start, budget.period));
  }

  static DateTime _monthAnchoredStart(
    DateTime anchor,
    DateTime nowUtc, {
    required int months,
  }) {
    final elapsedMonths =
        (nowUtc.year - anchor.year) * 12 + nowUtc.month - anchor.month;
    final elapsedPeriods = elapsedMonths ~/ months * months;
    final start = _addMonths(anchor, elapsedPeriods);
    if (start.isAfter(nowUtc)) {
      return _addMonths(anchor, elapsedPeriods - months);
    }
    return start;
  }

  static DateTime _addBudgetPeriod(DateTime start, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.daily:
        return start.add(const Duration(days: 1));
      case BudgetPeriod.weekly:
        return start.add(const Duration(days: 7));
      case BudgetPeriod.monthly:
        return _addMonths(start, 1);
      case BudgetPeriod.yearly:
        return _addMonths(start, 12);
    }
  }

  /// Adds [months] to [start], clamping the day to the target month length.
  static DateTime _addMonths(DateTime start, int months) {
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
