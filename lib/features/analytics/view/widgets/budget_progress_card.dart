import 'package:finecho/app/theme/fin_echo_theme.dart';
import 'package:finecho/core/models/currency_minor_units.dart';
import 'package:finecho/features/analytics/view_model/models/budget_progress.dart';
import 'package:flutter/material.dart';

const String _title = 'Budgets';

/// A card that tracks spending against each budget.
class BudgetProgressCard extends StatelessWidget {
  /// Creates the budget progress card.
  const new({required this.budgetProgress, this.currency, super.key});

  /// Spending against every budget, most severe first.
  final List<BudgetProgress> budgetProgress;

  /// The ISO currency code the spent amounts are denominated in. Spending is
  /// aggregated in the dashboard primary currency.
  final String? currency;

  @override
  Widget build(BuildContext context) {
    if (budgetProgress.isEmpty) {
      return const SizedBox.shrink();
    }
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
            const SizedBox(height: 8),
            for (final progress in budgetProgress)
              _BudgetRow(progress, currency: currency),
          ],
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const new(this.progress, {required this.currency});

  final BudgetProgress progress;

  /// The ISO currency code the amounts are denominated in.
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExceeded = progress.level == BudgetProgressLevel.exceeded;
    final isWarning = progress.level == BudgetProgressLevel.warning;
    final statusLabel = switch (progress.level) {
      BudgetProgressLevel.normal => null,
      BudgetProgressLevel.warning => 'Close to limit',
      BudgetProgressLevel.exceeded => 'Over budget',
    };
    final barColor = isExceeded
        ? theme.colorScheme.error
        : isWarning
        ? FinEchoColors.coral
        : theme.colorScheme.primary;
    final spentLabel = formatMinorUnits(
      progress.spentAmountMinorUnits,
      currency,
    );
    final allocatedLabel = formatMinorUnits(
      progress.allocatedAmountMinorUnits,
      currency,
    );
    final semanticsValue =
        '$spentLabel of $allocatedLabel spent'
        '${statusLabel == null ? '' : ', ${statusLabel.toLowerCase()}'}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.categoryName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$spentLabel / $allocatedLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: '${progress.categoryName} budget',
            value: semanticsValue,
            child: LinearProgressIndicator(
              value: progress.usedRatio.clamp(0.0, 1.0),
              color: barColor,
            ),
          ),
          if (statusLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              statusLabel,
              style: theme.textTheme.labelSmall?.copyWith(color: barColor),
            ),
          ],
        ],
      ),
    );
  }
}
