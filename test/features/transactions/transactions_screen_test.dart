import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/transactions/view/screens/transactions_screen.dart';
import 'package:finecho/features/transactions/view/widgets/transaction_tile.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_transaction_repositories.dart';

const String _invalidAmountMessage = 'Enter an amount greater than zero.';

Account _account(String id, String name) {
  return Account(
    id: id,
    name: name,
    type: AccountType.bank,
    currency: 'EGP',
    balanceMinorUnits: 100000,
  );
}

Category _category(String id, String name) {
  return Category(id: id, name: name, iconKey: 'label', colorHex: '#FF5722');
}

Transaction _transaction({
  required String id,
  required String accountId,
  required String? categoryId,
  required int amountMinorUnits,
  required DateTime timestamp,
  required TransactionType type,
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    categoryId: categoryId,
    amountMinorUnits: amountMinorUnits,
    timestamp: timestamp,
    type: type,
    source: TransactionSource.manual,
  );
}

Widget wrapScreen(TransactionsCubit cubit, Widget child) {
  return MaterialApp(
    home: BlocProvider<TransactionsCubit>.value(value: cubit, child: child),
  );
}

Future<TransactionsCubit> createLoadedCubit(
  TransactionsTestHarness harness,
) async {
  final cubit = TransactionsCubit(harness.service);
  addTearDown(cubit.close);
  await cubit.load();
  return cubit;
}

Future<void> openAddSheet(WidgetTester tester) async {
  await tester.tap(find.text('Add transaction'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the blocked state when no accounts exist', (tester) async {
    final harness = TransactionsTestHarness(
      now: () => DateTime.utc(2026, 10, 15),
    );
    final cubit = await createLoadedCubit(harness);

    await tester.pumpWidget(wrapScreen(cubit, const TransactionsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No accounts yet'), findsOneWidget);
    expect(
      find.text('Add an account to start tracking transactions.'),
      findsOneWidget,
    );
  });

  testWidgets('shows seeded transaction rows with categories', (tester) async {
    final account = _account('account-1', 'Main bank');
    final food = _category('category-1', 'Food');
    final salary = _category('category-2', 'Salary');
    final expense = _transaction(
      id: 'txn-1',
      accountId: account.id,
      categoryId: food.id,
      amountMinorUnits: 1250,
      timestamp: DateTime.utc(2026, 10, 14),
      type: TransactionType.expense,
    );
    final income = _transaction(
      id: 'txn-2',
      accountId: account.id,
      categoryId: salary.id,
      amountMinorUnits: 50000,
      timestamp: DateTime.utc(2026, 10, 15),
      type: TransactionType.income,
    );
    final harness = TransactionsTestHarness(
      initialTransactions: {expense.id: expense, income.id: income},
      initialAccounts: {account.id: account},
      initialCategories: {food.id: food, salary.id: salary},
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    final cubit = await createLoadedCubit(harness);

    await tester.pumpWidget(wrapScreen(cubit, const TransactionsScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionTile), findsNWidgets(2));
    expect(find.text('-12.50'), findsOneWidget);
    expect(find.text('+500.00'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('2026-10-15'), findsOneWidget);
  });

  testWidgets('saves a manual transaction from the add sheet', (tester) async {
    final account = _account('account-1', 'Main bank');
    final harness = TransactionsTestHarness(
      initialAccounts: {account.id: account},
      now: () => DateTime.utc(2026, 10, 15, 12),
      newId: () => 'txn-new',
    );
    final cubit = await createLoadedCubit(harness);

    await tester.pumpWidget(wrapScreen(cubit, const TransactionsScreen()));
    await tester.pumpAndSettle();
    await openAddSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, '12.50');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Amount'), findsNothing);
    expect(find.text('-12.50'), findsOneWidget);
    expect(harness.transactionRepository.transactions['txn-new'], isNotNull);
  });

  testWidgets('keeps the sheet open for an invalid amount', (tester) async {
    final account = _account('account-1', 'Main bank');
    final harness = TransactionsTestHarness(
      initialAccounts: {account.id: account},
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    final cubit = await createLoadedCubit(harness);

    await tester.pumpWidget(wrapScreen(cubit, const TransactionsScreen()));
    await tester.pumpAndSettle();
    await openAddSheet(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text(_invalidAmountMessage), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(harness.transactionRepository.transactions, isEmpty);
  });

  testWidgets('renders transaction rows in an RTL tree', (tester) async {
    final account = _account('account-1', 'Main bank');
    final food = _category('category-1', 'Food');
    final expense = _transaction(
      id: 'txn-1',
      accountId: account.id,
      categoryId: food.id,
      amountMinorUnits: 1250,
      timestamp: DateTime.utc(2026, 10, 14),
      type: TransactionType.expense,
    );
    final harness = TransactionsTestHarness(
      initialTransactions: {expense.id: expense},
      initialAccounts: {account.id: account},
      initialCategories: {food.id: food},
      now: () => DateTime.utc(2026, 10, 15, 12),
    );
    final cubit = await createLoadedCubit(harness);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: wrapScreen(cubit, const TransactionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TransactionTile), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
  });
}
