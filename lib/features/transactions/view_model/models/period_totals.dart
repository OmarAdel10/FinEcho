import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/core/models/period_range.dart';
import 'package:finecho/core/models/transaction.dart';

/// Income, expense, and net totals for one analytics period.
class PeriodTotals {
  /// Creates totals for the period that starts at [startUtc] and ends
  /// before [endUtc].
  const new({
    required this.startUtc,
    required this.endUtc,
    required this.incomeMinorUnits,
    required this.expenseMinorUnits,
  });

  /// The UTC instant the period starts.
  final DateTime startUtc;

  /// The exclusive UTC instant the period ends.
  final DateTime endUtc;

  /// Total income in minor units.
  final int incomeMinorUnits;

  /// Total expenses in minor units.
  final int expenseMinorUnits;

  /// Income minus expenses in minor units.
  int get netMinorUnits => incomeMinorUnits - expenseMinorUnits;
}

/// Sums income and expenses from [transactions] inside the [period]
/// containing [now], using the local calendar described by
/// [localUtcOffset].
///
/// Transfers are excluded because they move money between accounts
/// instead of changing it.
PeriodTotals computePeriodTotals({
  required List<Transaction> transactions,
  required AnalyticsPeriod period,
  required DateTime now,
  required Duration localUtcOffset,
}) {
  final (startUtc, endUtc) = periodRange(period, now.toUtc(), localUtcOffset);
  var incomeMinorUnits = 0;
  var expenseMinorUnits = 0;
  for (final transaction in transactions) {
    final timestamp = transaction.timestamp;
    if (timestamp.isBefore(startUtc) || !timestamp.isBefore(endUtc)) {
      continue;
    }
    switch (transaction.type) {
      case TransactionType.income:
        incomeMinorUnits += transaction.amountMinorUnits;
      case TransactionType.expense:
        expenseMinorUnits += transaction.amountMinorUnits;
      case TransactionType.transfer:
        break;
    }
  }
  return PeriodTotals(
    startUtc: startUtc,
    endUtc: endUtc,
    incomeMinorUnits: incomeMinorUnits,
    expenseMinorUnits: expenseMinorUnits,
  );
}
