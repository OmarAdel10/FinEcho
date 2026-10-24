import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/transactions/view_model/models/period_totals.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _transaction({
  required String id,
  required DateTime timestamp,
  required TransactionType type,
  int amountMinorUnits = 1000,
}) {
  return Transaction(
    id: id,
    accountId: 'account-1',
    amountMinorUnits: amountMinorUnits,
    timestamp: timestamp,
    type: type,
    source: TransactionSource.manual,
  );
}

void main() {
  final now = DateTime.utc(2026, 10, 15, 12);

  group('computePeriodTotals', () {
    test('covers the local calendar month containing now', () {
      final totals = computePeriodTotals(
        transactions: const [],
        period: AnalyticsPeriod.month,
        now: now,
        localUtcOffset: Duration.zero,
      );

      expect(totals.startUtc, DateTime.utc(2026, 10));
      expect(totals.endUtc, DateTime.utc(2026, 11));
      expect(totals.incomeMinorUnits, 0);
      expect(totals.expenseMinorUnits, 0);
      expect(totals.netMinorUnits, 0);
    });

    test('sums only the transactions inside the month', () {
      final income = _transaction(
        id: 'txn-1',
        timestamp: DateTime.utc(2026, 10, 14),
        type: TransactionType.income,
        amountMinorUnits: 50000,
      );
      final expense = _transaction(
        id: 'txn-2',
        timestamp: DateTime.utc(2026, 10, 2),
        type: TransactionType.expense,
        amountMinorUnits: 1250,
      );
      final previousMonth = _transaction(
        id: 'txn-3',
        timestamp: DateTime.utc(2026, 9, 30),
        type: TransactionType.expense,
        amountMinorUnits: 999,
      );
      final exclusiveEnd = _transaction(
        id: 'txn-4',
        timestamp: DateTime.utc(2026, 11),
        type: TransactionType.income,
        amountMinorUnits: 777,
      );

      final totals = computePeriodTotals(
        transactions: [income, expense, previousMonth, exclusiveEnd],
        period: AnalyticsPeriod.month,
        now: now,
        localUtcOffset: Duration.zero,
      );

      expect(totals.incomeMinorUnits, 50000);
      expect(totals.expenseMinorUnits, 1250);
      expect(totals.netMinorUnits, 48750);
    });

    test('excludes transfers', () {
      final transfer = _transaction(
        id: 'txn-1',
        timestamp: DateTime.utc(2026, 10, 14),
        type: TransactionType.transfer,
        amountMinorUnits: 50000,
      );

      final totals = computePeriodTotals(
        transactions: [transfer],
        period: AnalyticsPeriod.month,
        now: now,
        localUtcOffset: Duration.zero,
      );

      expect(totals.incomeMinorUnits, 0);
      expect(totals.expenseMinorUnits, 0);
      expect(totals.netMinorUnits, 0);
    });

    test('reports a negative net when expenses exceed income', () {
      final income = _transaction(
        id: 'txn-1',
        timestamp: DateTime.utc(2026, 10, 14),
        type: TransactionType.income,
        amountMinorUnits: 1250,
      );
      final expense = _transaction(
        id: 'txn-2',
        timestamp: DateTime.utc(2026, 10, 14),
        type: TransactionType.expense,
        amountMinorUnits: 50000,
      );

      final totals = computePeriodTotals(
        transactions: [income, expense],
        period: AnalyticsPeriod.month,
        now: now,
        localUtcOffset: Duration.zero,
      );

      expect(totals.netMinorUnits, -48750);
    });

    test('covers the week that starts on Monday', () {
      final sunday = _transaction(
        id: 'txn-1',
        timestamp: DateTime.utc(2026, 10, 11),
        type: TransactionType.expense,
        amountMinorUnits: 100,
      );
      final monday = _transaction(
        id: 'txn-2',
        timestamp: DateTime.utc(2026, 10, 12),
        type: TransactionType.expense,
        amountMinorUnits: 200,
      );

      final totals = computePeriodTotals(
        transactions: [sunday, monday],
        period: AnalyticsPeriod.week,
        now: now,
        localUtcOffset: Duration.zero,
      );

      expect(totals.startUtc, DateTime.utc(2026, 10, 12));
      expect(totals.endUtc, DateTime.utc(2026, 10, 19));
      expect(totals.expenseMinorUnits, 200);
    });

    test('covers the calendar year', () {
      final previousYear = _transaction(
        id: 'txn-1',
        timestamp: DateTime.utc(2025, 12, 31),
        type: TransactionType.expense,
        amountMinorUnits: 100,
      );
      final january = _transaction(
        id: 'txn-2',
        timestamp: DateTime.utc(2026),
        type: TransactionType.expense,
        amountMinorUnits: 200,
      );

      final totals = computePeriodTotals(
        transactions: [previousYear, january],
        period: AnalyticsPeriod.year,
        now: now,
        localUtcOffset: Duration.zero,
      );

      expect(totals.startUtc, DateTime.utc(2026));
      expect(totals.endUtc, DateTime.utc(2027));
      expect(totals.expenseMinorUnits, 200);
    });

    test('honors a non-zero local UTC offset', () {
      const offset = Duration(hours: 3);
      final eastOfUtcNow = DateTime.utc(2026, 10, 15, 12);

      // Sep 30, 22:00 UTC is already Oct 1 in a UTC+3 calendar.
      final localOctober = _transaction(
        id: 'txn-1',
        timestamp: DateTime.utc(2026, 9, 30, 22),
        type: TransactionType.expense,
        amountMinorUnits: 100,
      );
      final localSeptember = _transaction(
        id: 'txn-2',
        timestamp: DateTime.utc(2026, 9, 30, 20),
        type: TransactionType.expense,
        amountMinorUnits: 200,
      );

      final totals = computePeriodTotals(
        transactions: [localOctober, localSeptember],
        period: AnalyticsPeriod.month,
        now: eastOfUtcNow,
        localUtcOffset: offset,
      );

      expect(totals.startUtc, DateTime.utc(2026, 9, 30, 21));
      expect(totals.endUtc, DateTime.utc(2026, 10, 31, 21));
      expect(totals.expenseMinorUnits, 100);
    });
  });
}
