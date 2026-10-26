import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/transactions/view/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget _wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('TransactionTile', () {
    testWidgets('renders expense with minus prefix', (tester) async {
      final transaction = Transaction(
        id: 'txn-1',
        accountId: 'account-1',
        type: TransactionType.expense,
        amountMinorUnits: 1234,
        timestamp: DateTime.utc(2026, 10, 15, 12),
        source: TransactionSource.manual,
      );

      await tester.pumpWidget(_wrap(TransactionTile(transaction: transaction)));

      expect(find.text('-12.34'), findsOneWidget);
    });

    testWidgets('renders income with plus prefix', (tester) async {
      final transaction = Transaction(
        id: 'txn-2',
        accountId: 'account-1',
        type: TransactionType.income,
        amountMinorUnits: 5000,
        timestamp: DateTime.utc(2026, 10, 15, 12),
        source: TransactionSource.manual,
      );

      await tester.pumpWidget(_wrap(TransactionTile(transaction: transaction)));

      expect(find.text('+50.00'), findsOneWidget);
    });

    testWidgets('renders transfer with no prefix', (tester) async {
      final transaction = Transaction(
        id: 'txn-3',
        accountId: 'account-1',
        type: TransactionType.transfer,
        amountMinorUnits: 2500,
        timestamp: DateTime.utc(2026, 10, 15, 12),
        source: TransactionSource.manual,
      );

      await tester.pumpWidget(_wrap(TransactionTile(transaction: transaction)));

      expect(find.text('25.00'), findsOneWidget);
    });

    testWidgets('formats JPY amount with zero decimals', (tester) async {
      final transaction = Transaction(
        id: 'txn-4',
        accountId: 'account-jpy',
        type: TransactionType.expense,
        amountMinorUnits: 1234,
        timestamp: DateTime.utc(2026, 10, 15, 12),
        source: TransactionSource.manual,
      );

      await tester.pumpWidget(
        _wrap(
          TransactionTile(transaction: transaction, accountCurrency: 'JPY'),
        ),
      );

      expect(find.text('-1234'), findsOneWidget);
    });
  });
}
