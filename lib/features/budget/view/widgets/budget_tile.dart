import 'package:finecho/core/models/budget.dart';
import 'package:flutter/material.dart';

/// A presentational row for a single budget.
class BudgetTile extends StatelessWidget {
  /// Creates a budget row.
  const new({required this.budget, this.categoryName, this.onTap, super.key});

  /// The budget to display.
  final Budget budget;

  /// The resolved category name.
  final String? categoryName;

  /// Called when the user selects the budget.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.account_balance_wallet)),
      title: Text(categoryName ?? 'Uncategorized'),
      subtitle: Text(
        '${_periodTitle(budget.period)} • '
        '${_formatDate(budget.startDate)}',
      ),
      trailing: Text(
        _amountLabel(budget),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatDate(DateTime timestamp) {
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    return '${timestamp.year}-$month-$day';
  }

  String _periodTitle(BudgetPeriod period) {
    final name = period.name;
    if (name.isEmpty) {
      return '';
    }
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  String _amountLabel(Budget budget) {
    if (budget.allocatedAmountMinorUnits <= 0) {
      return r'$0.00';
    }
    final major = budget.allocatedAmountMinorUnits ~/ 100;
    final fraction = (budget.allocatedAmountMinorUnits % 100)
        .toString()
        .padLeft(2, '0');
    return '\$$major.$fraction';
  }
}
