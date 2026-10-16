import 'package:finecho/core/models/transaction.dart';
import 'package:flutter/material.dart';

const String _uncategorizedLabel = 'Uncategorized';

/// A presentational row for a single transaction.
class TransactionTile extends StatelessWidget {
  /// Creates a transaction row.
  const new({
    required this.transaction,
    this.categoryName,
    this.onTap,
    super.key,
  });

  /// The transaction to display.
  final Transaction transaction;

  /// The resolved category name, or null when uncategorized.
  final String? categoryName;

  /// Called when the user selects the transaction.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Icon(_iconFor(transaction.type))),
      title: Text(categoryName ?? _uncategorizedLabel),
      subtitle: Text(_formatDate(transaction.timestamp)),
      trailing: Text(
        _amountLabel(transaction),
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  IconData _iconFor(TransactionType type) {
    return switch (type) {
      TransactionType.expense => Icons.south_east,
      TransactionType.income => Icons.north_east,
      TransactionType.transfer => Icons.swap_horiz,
    };
  }

  String _formatDate(DateTime timestamp) {
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    return '${timestamp.year}-$month-$day';
  }

  String _amountLabel(Transaction transaction) {
    final major = transaction.amountMinorUnits ~/ 100;
    final fraction = (transaction.amountMinorUnits % 100).toString().padLeft(
      2,
      '0',
    );
    final prefix = switch (transaction.type) {
      TransactionType.expense => '-',
      TransactionType.income => '+',
      TransactionType.transfer => '',
    };
    return '$prefix$major.$fraction';
  }
}
