import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/transactions/view_model/services/transaction_service.dart';
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

void main() {
  group('TransactionService', () {
    test('rejects a zero amount', () async {
      final harness = TransactionsTestHarness(
        initialAccounts: {'account-1': _account()},
      );

      await expectLater(
        harness.service.addTransaction(
          accountId: 'account-1',
          type: TransactionType.expense,
          amountMinorUnits: 0,
        ),
        throwsA(
          isA<TransactionValidationException>().having(
            (error) => error.message,
            'message',
            'Enter an amount greater than zero.',
          ),
        ),
      );
      expect(harness.transactionRepository.createdIds, isEmpty);
    });

    test('rejects a negative amount', () async {
      final harness = TransactionsTestHarness(
        initialAccounts: {'account-1': _account()},
      );

      await expectLater(
        harness.service.addTransaction(
          accountId: 'account-1',
          type: TransactionType.income,
          amountMinorUnits: -1,
        ),
        throwsA(
          isA<TransactionValidationException>().having(
            (error) => error.message,
            'message',
            'Enter an amount greater than zero.',
          ),
        ),
      );
      expect(harness.transactionRepository.createdIds, isEmpty);
    });

    test('rejects an unknown account', () async {
      final harness = TransactionsTestHarness();

      await expectLater(
        harness.service.addTransaction(
          accountId: 'missing-account',
          type: TransactionType.expense,
          amountMinorUnits: 100,
        ),
        throwsA(
          isA<TransactionValidationException>().having(
            (error) => error.message,
            'message',
            'Choose a valid account.',
          ),
        ),
      );
      expect(harness.transactionRepository.createdIds, isEmpty);
    });

    test('rejects an unknown category', () async {
      final harness = TransactionsTestHarness(
        initialAccounts: {'account-1': _account()},
      );

      await expectLater(
        harness.service.addTransaction(
          accountId: 'account-1',
          type: TransactionType.expense,
          amountMinorUnits: 100,
          categoryId: 'missing-category',
        ),
        throwsA(
          isA<TransactionValidationException>().having(
            (error) => error.message,
            'message',
            'Choose a valid category.',
          ),
        ),
      );
      expect(harness.transactionRepository.createdIds, isEmpty);
    });

    test('persists a manual transaction with injected values', () async {
      final now = DateTime.utc(2026, 10, 15, 12);
      final harness = TransactionsTestHarness(
        initialAccounts: {'account-1': _account()},
        initialCategories: {'category-1': _category()},
        now: () => now,
        newId: () => 'txn-new',
      );

      final transaction = await harness.service.addTransaction(
        accountId: 'account-1',
        type: TransactionType.expense,
        amountMinorUnits: 2500,
        categoryId: 'category-1',
        note: 'Lunch',
      );

      expect(transaction.id, 'txn-new');
      expect(transaction.accountId, 'account-1');
      expect(transaction.categoryId, 'category-1');
      expect(transaction.amountMinorUnits, 2500);
      expect(transaction.timestamp, now);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.source, TransactionSource.manual);
      expect(transaction.rawText, 'Lunch');
      expect(harness.transactionRepository.createdIds, <String>['txn-new']);
      expect(
        harness.transactionRepository.transactions['txn-new'],
        transaction,
      );
    });

    test('updates a transaction and clears optional fields', () async {
      final originalTimestamp = DateTime.utc(2026, 10, 14, 9);
      final original = Transaction(
        id: 'txn-1',
        accountId: 'account-1',
        categoryId: 'category-1',
        amountMinorUnits: 1000,
        timestamp: originalTimestamp,
        type: TransactionType.expense,
        source: TransactionSource.sms,
        rawText: 'Original note',
      );
      final harness = TransactionsTestHarness(
        initialTransactions: {'txn-1': original},
        initialAccounts: {'account-1': _account()},
      );

      final updated = await harness.service.updateTransaction(
        original: original,
        accountId: 'account-1',
        type: TransactionType.income,
        amountMinorUnits: 2000,
      );

      expect(updated.id, original.id);
      expect(updated.source, TransactionSource.sms);
      expect(updated.accountId, 'account-1');
      expect(updated.categoryId, isNull);
      expect(updated.amountMinorUnits, 2000);
      expect(updated.timestamp, originalTimestamp);
      expect(updated.type, TransactionType.income);
      expect(updated.rawText, isNull);
      expect(harness.transactionRepository.updatedIds, <String>['txn-1']);
      expect(harness.transactionRepository.transactions['txn-1'], updated);
    });

    test('delegates deletion to the repository', () async {
      final original = Transaction(
        id: 'txn-1',
        accountId: 'account-1',
        amountMinorUnits: 1000,
        timestamp: DateTime.utc(2026, 10, 14, 9),
        type: TransactionType.expense,
        source: TransactionSource.manual,
      );
      final harness = TransactionsTestHarness(
        initialTransactions: {'txn-1': original},
      );

      await harness.service.deleteTransaction('txn-1');

      expect(harness.transactionRepository.deletedIds, <String>['txn-1']);
      expect(harness.transactionRepository.transactions, isEmpty);
    });

    test('lists transactions newest first', () async {
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
      final harness = TransactionsTestHarness(
        initialTransactions: {'txn-newer': newer, 'txn-older': older},
      );

      final transactions = await harness.service.listTransactions();

      expect(transactions.map((transaction) => transaction.id), <String>[
        'txn-newer',
        'txn-older',
      ]);
    });
  });
}
