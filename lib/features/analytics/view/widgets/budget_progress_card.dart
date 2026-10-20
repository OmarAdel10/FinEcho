import 'package:finecho/app/theme/fin_echo_theme.dart';
import 'package:finecho/features/analytics/view_model/models/budget_progress.dart';
import 'package:flutter/material.dart';

const String _title = 'Budgets';

/// A card that tracks spending against each budget.
class BudgetProgressCard extends StatelessWidget {
  /// Creates the budget progress card.
  const new({required this.budgetProgress, super.key});

  /// Spending against every budget, most severe first.
  final List<BudgetProgress> budgetProgress;

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
            for (final progress in budgetProgress) _BudgetRow(progress),
          ],
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const new(this.progress);

  final BudgetProgress progress;

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
    final semanticsValue =
        '${_formatMinorUnits(progress.spentAmountMinorUnits)} of '
        '${_formatMinorUnits(progress.allocatedAmountMinorUnits)} spent'
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
                '${_formatMinorUnits(progress.spentAmountMinorUnits)} / '
                '${_formatMinorUnits(progress.allocatedAmountMinorUnits)}',
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

String _formatMinorUnits(int amount) {
  final sign = amount < 0 ? '-' : '';
  final absolute = amount.abs();
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '$sign${absolute ~/ 100}.$fraction';
}
