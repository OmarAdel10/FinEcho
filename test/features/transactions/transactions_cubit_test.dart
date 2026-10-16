import 'dart:async';

import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/transactions/view_model/models/transactions_state.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_transaction_repositories.dart';

Account _account() {
  return const Account(
    id: 'account-1',
    name: 'Cash',
    type: AccountType.cash,
    currency: 'EGP',
    balanceMinorUnits: 10000,
  );
}

Category _category() {
  return const Category(
    id: 'category-1',
    name: 'Food',
    iconKey: 'restaurant',
    colorHex: '#FF5722',
  );
}

TransactionsTestHarness _harness({
  Map<String, Transaction> initialTransactions = const {},
}) {
  return TransactionsTestHarness(
    initialTransactions: initialTransactions,
    initialAccounts: {'account-1': _account()},
    initialCategories: {'category-1': _category()},
    now: () => DateTime.utc(2026, 10, 15, 12),
    newId: () => 'txn-new',
  );
}

void main() {
  late TransactionsTestHarness harness;
  late TransactionsCubit cubit;

  setUp(() {
    harness = _harness();
    cubit = TransactionsCubit(harness.service);
  });

  tearDown(() => cubit.close());

  group('TransactionsCubit', () {
    test('loads sorted transactions, accounts, and categories', () async {
      final older = Transaction(
        id: 'txn-older',
        accountId: 'account-1',
        amountMinorUnits: 1000,
        timestamp: DateTime.utc(2026, 10, 14, 9),
        type: TransactionType.expense,
        source: TransactionSource.manual,
      );
      final newer = Transaction(
        id: 'txn-newer',
        accountId: 'account-1',
        amountMinorUnits: 2000,
        timestamp: DateTime.utc(2026, 10, 15, 9),
        type: TransactionType.income,
        source: TransactionSource.manual,
      );
      harness = _harness(
        initialTransactions: {'txn-newer': newer, 'txn-older': older},
      );
      cubit = TransactionsCubit(harness.service);

      await cubit.load();

      expect(cubit.state.status, TransactionsStatus.ready);
      expect(
        cubit.state.transactions.map((transaction) => transaction.id),
        <String>['txn-newer', 'txn-older'],
      );
      expect(cubit.state.accounts.single.id, 'account-1');
      expect(cubit.state.categories.single.id, 'category-1');
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('reports a load failure', () async {
      harness.transactionRepository.listError = Exception('load failed');

      await cubit.load();

      expect(cubit.state.status, TransactionsStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Could not load transactions. Please try again.',
      );
    });

    test('adds a transaction and refreshes ready state', () async {
      await cubit.load();
      final saved = await cubit.addTransaction(
        accountId: 'account-1',
        type: TransactionType.expense,
        amountMinorUnits: 2500,
        categoryId: 'category-1',
        note: 'Lunch',
      );

      expect(saved, isTrue);
      expect(cubit.state.status, TransactionsStatus.ready);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.transactions.single.id, 'txn-new');
      expect(harness.transactionRepository.createdIds, <String>['txn-new']);
    });

    test('surfaces an add validation failure', () async {
      await cubit.load();
      final saved = await cubit.addTransaction(
        accountId: 'missing-account',
        type: TransactionType.expense,
        amountMinorUnits: 2500,
      );

      expect(saved, isFalse);
      expect(cubit.state.status, TransactionsStatus.failure);
      expect(cubit.state.errorMessage, 'Choose a valid account.');
      expect(harness.transactionRepository.createdIds, isEmpty);
    });

    test('reports an add repository failure', () async {
      await cubit.load();
      harness.transactionRepository.createError = Exception('create failed');
      final saved = await cubit.addTransaction(
        accountId: 'account-1',
        type: TransactionType.expense,
        amountMinorUnits: 2500,
      );

      expect(saved, isFalse);
      expect(cubit.state.status, TransactionsStatus.failure);
      expect(
        cubit.state.errorMessage,
        'Could not save the transaction. Please try again.',
      );
    });

    test('updates a transaction and replaces the old row', () async {
      final original = Transaction(
        id: 'txn-1',
        accountId: 'account-1',
        categoryId: 'category-1',
        amountMinorUnits: 1000,
        timestamp: DateTime.utc(2026, 10, 14, 9),
        type: TransactionType.expense,
        source: TransactionSource.sms,
      );
      harness = _harness(initialTransactions: {'txn-1': original});
      cubit = TransactionsCubit(harness.service);
      await cubit.load();
      final saved = await cubit.updateTransaction(
        original: original,
        accountId: 'account-1',
        type: TransactionType.income,
        amountMinorUnits: 2000,
      );

      expect(saved, isTrue);
      expect(cubit.state.status, TransactionsStatus.ready);
      expect(cubit.state.transactions.single.amountMinorUnits, 2000);
      expect(cubit.state.transactions.single.type, TransactionType.income);
      expect(cubit.state.transactions.single.source, TransactionSource.sms);
      expect(harness.transactionRepository.updatedIds, <String>['txn-1']);
    });

    test('deletes a transaction and refreshes ready state', () async {
      final original = Transaction(
        id: 'txn-1',
        accountId: 'account-1',
        amountMinorUnits: 1000,
        timestamp: DateTime.utc(2026, 10, 14, 9),
        type: TransactionType.expense,
        source: TransactionSource.manual,
      );
      harness = _harness(initialTransactions: {'txn-1': original});
      cubit = TransactionsCubit(harness.service);
      await cubit.load();
      final deleted = await cubit.deleteTransaction('txn-1');

      expect(deleted, isTrue);
      expect(cubit.state.status, TransactionsStatus.ready);
      expect(cubit.state.transactions, isEmpty);
      expect(harness.transactionRepository.deletedIds, <String>['txn-1']);
    });

    test('ignores an add while another add is submitting', () async {
      await cubit.load();
      harness.transactionRepository.createGate = Completer<void>();
      final first = cubit.addTransaction(
        accountId: 'account-1',
        type: TransactionType.expense,
        amountMinorUnits: 2500,
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isSubmitting, isTrue);
      final second = await cubit.addTransaction(
        accountId: 'account-1',
        type: TransactionType.expense,
        amountMinorUnits: 1000,
      );

      expect(second, isFalse);
      expect(harness.transactionRepository.createdIds, isEmpty);
      harness.transactionRepository.createGate!.complete();
      expect(await first, isTrue);
      expect(harness.transactionRepository.createdIds, <String>['txn-new']);
    });
  });
}
