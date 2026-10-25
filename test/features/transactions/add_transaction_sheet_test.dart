import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/transactions/view/widgets/add_transaction_sheet.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_transaction_repositories.dart';

Account _account() {
  return const Account(
    id: 'account-1',
    name: 'Main bank',
    type: AccountType.bank,
    currency: 'EGP',
    balanceMinorUnits: 100000,
  );
}

Category _category() {
  return const Category(
    id: 'category-1',
    name: 'Food',
    iconKey: 'label',
    colorHex: '#FF5722',
  );
}

Transaction _transaction({required int amountMinorUnits}) {
  return Transaction(
    id: 'txn-1',
    accountId: 'account-1',
    categoryId: 'category-1',
    amountMinorUnits: amountMinorUnits,
    timestamp: DateTime.utc(2026, 10, 14),
    type: TransactionType.expense,
    source: TransactionSource.manual,
  );
}

Future<TransactionsTestHarness> _pumpSheet(
  WidgetTester tester, {
  required Transaction transaction,
}) async {
  final harness = TransactionsTestHarness(
    initialTransactions: {transaction.id: transaction},
    initialAccounts: {'account-1': _account()},
    initialCategories: {'category-1': _category()},
    now: () => DateTime.utc(2026, 10, 15),
  );
  final cubit = TransactionsCubit(harness.service);
  addTearDown(cubit.close);
  await cubit.load();

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<TransactionsCubit>.value(
        value: cubit,
        child: Scaffold(body: AddTransactionSheet(initial: transaction)),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return harness;
}

void main() {
  testWidgets('prefills the amount when editing a transaction', (tester) async {
    await _pumpSheet(
      tester,
      transaction: _transaction(amountMinorUnits: 12345),
    );

    expect(find.text('123.45'), findsOneWidget);
  });

  testWidgets('saves an edit with the prefilled amount', (tester) async {
    final transaction = _transaction(amountMinorUnits: 12345);
    final harness = await _pumpSheet(tester, transaction: transaction);

    final saveButton = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(harness.transactionRepository.updatedIds, ['txn-1']);
    expect(
      harness.transactionRepository.transactions['txn-1']?.amountMinorUnits,
      12345,
    );
  });

  testWidgets('keeps a single cent visible when editing', (tester) async {
    await _pumpSheet(tester, transaction: _transaction(amountMinorUnits: 5));

    expect(find.text('0.05'), findsOneWidget);
  });
}
