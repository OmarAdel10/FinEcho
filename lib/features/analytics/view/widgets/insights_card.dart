import 'package:finecho/app/theme/fin_echo_theme.dart';
import 'package:finecho/core/models/currency_minor_units.dart';
import 'package:finecho/features/analytics/view_model/models/category_spike.dart';
import 'package:finecho/features/analytics/view_model/models/monthly_forecast.dart';
import 'package:finecho/features/analytics/view_model/models/recurring_charge.dart';
import 'package:flutter/material.dart';

const String _title = 'Insights';
const String _monthNote = 'Current calendar month';
const String _forecastTitle = 'Projected month-end spending';
const String _recurringTitle = 'Recurring charges';
const String _spikesTitle = 'Unusual spending';
const String _noRecurringMessage = 'No recurring charges yet.';
const String _noSpikesMessage = 'No unusual spending.';

/// A card that surfaces the forecast, recurring charges, and spending spikes.
class InsightsCard extends StatelessWidget {
  /// Creates the insights card.
  const new({
    required this.forecast,
    required this.recurringCharges,
    required this.unusualSpikes,
    this.currency,
    super.key,
  });

  /// The projected expenses, recurring charges, and unusual spikes are all
  /// aggregated in this currency.
  final String? currency;

  /// The projection for the current calendar month.
  final MonthlyForecast forecast;

  /// Expenses repeating across months, strongest recurrence first.
  final List<RecurringCharge> recurringCharges;

  /// Categories spending far above their recent average, highest first.
  final List<CategorySpike> unusualSpikes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _monthNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const _SectionTitle(_forecastTitle),
            const SizedBox(height: 4),
            Text(
              formatMinorUnits(forecast.projectedExpenseMinorUnits, currency),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Based on ${forecast.elapsedDays} of '
              '${forecast.daysInMonth} days so far',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const _SectionTitle(_recurringTitle),
            if (recurringCharges.isEmpty)
              const Text(_noRecurringMessage)
            else
              for (final charge in recurringCharges)
                _RecurringRow(charge, currency: currency),
            const SizedBox(height: 16),
            const _SectionTitle(_spikesTitle),
            if (unusualSpikes.isEmpty)
              const Text(_noSpikesMessage)
            else
              for (final spike in unusualSpikes)
                _SpikeRow(spike, currency: currency),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const new(this.charge, {required this.currency});

  final RecurringCharge charge;

  /// The ISO currency code the charge amounts are denominated in.
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(charge.name, overflow: TextOverflow.ellipsis)),
          Text('${charge.monthsSeen} months', style: theme.textTheme.bodySmall),
          const SizedBox(width: 12),
          Text(
            formatMinorUnits(charge.amountMinorUnits, currency),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpikeRow extends StatelessWidget {
  const new(this.spike, {required this.currency});

  final CategorySpike spike;

  /// The ISO currency code the spike amounts are denominated in.
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = ((spike.ratio - 1) * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: FinEchoColors.coral,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spike.name, overflow: TextOverflow.ellipsis),
                Text(
                  '$percent% above the recent average',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatMinorUnits(spike.currentExpenseMinorUnits, currency),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
