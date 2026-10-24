import 'package:finecho/core/models/analytics_account_total.dart';
import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/category_expense_total.dart';
import 'package:finecho/core/models/category_monthly_expense.dart';
import 'package:finecho/core/models/transaction.dart';

/// Reads derived FinEcho analytics from persisted transactions.
abstract interface class AnalyticsRepository {
  /// Returns analytics for the half-open UTC range [startUtc] to [endUtc].
  ///
  /// Transfers are excluded. Uncategorized expenses are returned with a `null`
  /// category id and name rather than a synthetic `'uncategorized'` key.
  ///
  /// When [currency] is non-null only transactions whose account uses that
  /// ISO currency code are aggregated.
  Future<AnalyticsSummary> summaryForRange({
    required DateTime startUtc,
    required DateTime endUtc,
    String? currency,
  });

  /// Returns per-account income and expense totals for the half-open UTC
  /// range [startUtc] to [endUtc].
  ///
  /// Transfers are excluded. Accounts without activity in the range are
  /// omitted.
  Future<List<AnalyticsAccountTotal>> accountTotalsForRange({
    required DateTime startUtc,
    required DateTime endUtc,
  });

  /// Returns expense totals grouped by category for the half-open UTC range
  /// [startUtc] to [endUtc].
  ///
  /// Transfers are excluded and uncategorized expenses are reported with a
  /// `null` category id.
  ///
  /// When [currency] is non-null only transactions whose account uses that
  /// ISO currency code are aggregated.
  Future<List<CategoryExpenseTotal>> expenseTotalsByCategoryForRange({
    required DateTime startUtc,
    required DateTime endUtc,
    String? currency,
  });

  /// Returns expense totals grouped by category and calendar month for the
  /// half-open UTC range [startUtc] to [endUtc].
  ///
  /// Months are encoded as `year * 12 + month` in UTC. Transfers are
  /// excluded and uncategorized expenses are reported with a `null` category
  /// id.
  ///
  /// When [currency] is non-null only transactions whose account uses that
  /// ISO currency code are aggregated.
  Future<List<CategoryMonthlyExpense>> expenseMonthlyTotalsByCategory({
    required DateTime startUtc,
    required DateTime endUtc,
    String? currency,
  });

  /// Returns the expense transactions in the half-open UTC range
  /// [startUtc] to [endUtc], ordered by timestamp.
  ///
  /// The window is bounded, so callers never scan the full ledger.
  ///
  /// When [currency] is non-null only transactions whose account uses that
  /// ISO currency code are returned.
  Future<List<Transaction>> expenseTransactionsForRange({
    required DateTime startUtc,
    required DateTime endUtc,
    String? currency,
  });
}
