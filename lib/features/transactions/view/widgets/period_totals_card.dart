import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/core/models/currency_minor_units.dart';
import 'package:finecho/features/transactions/view_model/models/period_totals.dart';
import 'package:flutter/material.dart';

const String _weeklyLabel = 'Weekly';
const String _monthlyLabel = 'Monthly';
const String _yearlyLabel = 'Yearly';
const String _incomeLabel = 'Income';
const String _expensesLabel = 'Expenses';
const String _netLabel = 'Net';

const List<String> _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// A compact home dashboard card with income, expenses, and net totals
/// for the selected period.
class PeriodTotalsCard extends StatelessWidget {
  /// Creates the period totals card.
  const new({
    required this.totals,
    required this.selectedPeriod,
    required this.onPeriodSelected,
    required this.localUtcOffset,
    super.key,
  });

  /// The totals displayed for the selected period.
  final PeriodTotals totals;

  /// The period the totals cover.
  final AnalyticsPeriod selectedPeriod;

  /// Called when the reader picks a different period.
  final ValueChanged<AnalyticsPeriod> onPeriodSelected;

  /// The local UTC offset used to caption the period boundaries.
  final Duration localUtcOffset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<AnalyticsPeriod>(
              segments: const [
                ButtonSegment(
                  value: AnalyticsPeriod.week,
                  label: Text(_weeklyLabel),
                ),
                ButtonSegment(
                  value: AnalyticsPeriod.month,
                  label: Text(_monthlyLabel),
                ),
                ButtonSegment(
                  value: AnalyticsPeriod.year,
                  label: Text(_yearlyLabel),
                ),
              ],
              selected: {selectedPeriod},
              onSelectionChanged: (selection) {
                onPeriodSelected(selection.first);
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PeriodMetric(
                    label: _incomeLabel,
                    amountMinorUnits: totals.incomeMinorUnits,
                  ),
                ),
                Expanded(
                  child: _PeriodMetric(
                    label: _expensesLabel,
                    amountMinorUnits: totals.expenseMinorUnits,
                  ),
                ),
                Expanded(
                  child: _PeriodMetric(
                    label: _netLabel,
                    amountMinorUnits: totals.netMinorUnits,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_caption, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  String get _caption {
    final startLocal = totals.startUtc.add(localUtcOffset);
    final endLocal = totals.endUtc
        .subtract(const Duration(milliseconds: 1))
        .add(localUtcOffset);
    return '${_shortDate(startLocal)} – ${_shortDate(endLocal)}';
  }

  static String _shortDate(DateTime local) {
    return '${_monthNames[local.month - 1]} ${local.day}, ${local.year}';
  }
}

class _PeriodMetric extends StatelessWidget {
  const new({required this.label, required this.amountMinorUnits});

  final String label;
  final int amountMinorUnits;

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
          formatMinorUnits(amountMinorUnits, null),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
