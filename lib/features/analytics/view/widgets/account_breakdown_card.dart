import 'dart:math' as math;

import 'package:finecho/features/analytics/view_model/models/account_total.dart';
import 'package:flutter/material.dart';

const String _title = 'By account';
const String _emptyMessage = 'No account activity in this period.';

/// A card that ranks accounts by their expense share for the period.
class AccountBreakdownCard extends StatelessWidget {
  /// Creates the account breakdown card.
  const new({required this.accountTotals, super.key});

  /// Income and expenses per account, highest expense first.
  final List<AccountTotal> accountTotals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxExpense = accountTotals
        .map((accountTotal) => accountTotal.expenseMinorUnits)
        .fold(0, math.max);

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
            if (accountTotals.isEmpty)
              const Text(_emptyMessage)
            else
              for (final accountTotal in accountTotals)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              accountTotal.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: maxExpense > 0
                                  ? (accountTotal.expenseMinorUnits /
                                            maxExpense)
                                        .clamp(0.0, 1.0)
                                  : 0.0,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _formatMinorUnits(accountTotal.netAmountMinorUnits),
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

String _formatMinorUnits(int amount) {
  final sign = amount < 0 ? '-' : '';
  final absolute = amount.abs();
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '$sign${absolute ~/ 100}.$fraction';
}
