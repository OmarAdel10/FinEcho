import 'package:finecho/core/models/currency_minor_units.dart';
import 'package:flutter/material.dart';

const String _incomeLabel = 'Income';
const String _expensesLabel = 'Expenses';
const String _netLabel = 'Net';
const String _noPreviousPeriodMessage = 'No previous period to compare';

/// A card that summarizes income, expenses, and net for one period.
class AnalyticsSummaryCard extends StatelessWidget {
  /// Creates the analytics summary card.
  const new({
    required this.totalIncomeMinorUnits,
    required this.totalExpenseMinorUnits,
    required this.netAmountMinorUnits,
    required this.expenseChangeRatio,
    this.currency,
    super.key,
  });

  /// Total income for the selected period in minor units.
  final int totalIncomeMinorUnits;

  /// Total expenses for the selected period in minor units.
  final int totalExpenseMinorUnits;

  /// Income minus expenses for the selected period in minor units.
  final int netAmountMinorUnits;

  /// The expense change versus the previous period, or `null` without history.
  final double? expenseChangeRatio;

  /// The ISO currency code the amounts are denominated in, or `null` when
  /// the user has no active accounts.
  final String? currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: _incomeLabel,
                    amountMinorUnits: totalIncomeMinorUnits,
                    currency: currency,
                  ),
                ),
                Expanded(
                  child: _SummaryMetric(
                    label: _expensesLabel,
                    amountMinorUnits: totalExpenseMinorUnits,
                    currency: currency,
                  ),
                ),
                Expanded(
                  child: _SummaryMetric(
                    label: _netLabel,
                    amountMinorUnits: netAmountMinorUnits,
                    currency: currency,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_trendLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  String get _trendLabel {
    final ratio = expenseChangeRatio;
    if (ratio == null) {
      return _noPreviousPeriodMessage;
    }
    final percent = (ratio * 100).round().abs();
    final direction = switch (ratio) {
      > 0 => 'up',
      < 0 => 'down',
      _ => 'flat',
    };
    return 'Spending $direction $percent% vs previous period';
  }
}

class _SummaryMetric extends StatelessWidget {
  const new({
    required this.label,
    required this.amountMinorUnits,
    required this.currency,
  });

  final String label;
  final int amountMinorUnits;

  /// The ISO currency code the amount is denominated in, or `null` when
  /// the user has no active accounts.
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatMinorUnits(amountMinorUnits, currency),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
