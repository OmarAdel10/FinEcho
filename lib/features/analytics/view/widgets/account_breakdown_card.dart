import 'dart:math' as math;

import 'package:finecho/features/analytics/view_model/models/account_total.dart';
import 'package:flutter/material.dart';

const String _title = 'By account';
const String _emptyMessage = 'No account activity in this period.';

/// The amount an account breakdown row highlights.
enum AccountBreakdownMetric {
  /// Highlights the account's expenses.
  expense,

  /// Highlights the account's income.
  income,
}

/// A card that ranks accounts by the selected metric for the period.
class AccountBreakdownCard extends StatelessWidget {
  /// Creates the account breakdown card.
  const new({
    required this.accountTotals,
    this.metric = AccountBreakdownMetric.expense,
    super.key,
  });

  /// Income and expenses per account, highest expense first.
  final List<AccountTotal> accountTotals;

  /// The metric highlighted by the progress bars and trailing amounts.
  final AccountBreakdownMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metricAmounts = accountTotals
        .map((accountTotal) => _metricAmount(accountTotal, metric))
        .toList();
    final maxAmount = metricAmounts.fold(0, math.max);
    final rows = [
      for (var index = 0; index < accountTotals.length; index++)
        (
          name: accountTotals[index].name,
          amountMinorUnits: metricAmounts[index],
          share: maxAmount > 0
              ? (metricAmounts[index] / maxAmount).clamp(0.0, 1.0)
              : 0.0,
        ),
    ];

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
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Text(_emptyMessage)
            else
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.name, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Semantics(
                              label: '${row.name} ${metric.name} share',
                              child: LinearProgressIndicator(value: row.share),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _formatMinorUnits(row.amountMinorUnits),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

int _metricAmount(AccountTotal accountTotal, AccountBreakdownMetric metric) {
  return switch (metric) {
    AccountBreakdownMetric.expense => accountTotal.expenseMinorUnits,
    AccountBreakdownMetric.income => accountTotal.incomeMinorUnits,
  };
}

String _formatMinorUnits(int amount) {
  final sign = amount < 0 ? '-' : '';
  final absolute = amount.abs();
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '$sign${absolute ~/ 100}.$fraction';
}
