import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Account model', () {
    const account = Account(
      id: 'account-1',
      name: 'Everyday',
      type: AccountType.bank,
      currency: 'EGP',
      balanceMinorUnits: 125000,
      maskedIdentifier: '1234',
      linkedAccountId: 'account-2',
    );

    test('round-trips through a SQLite row map', () {
      expect(Account.fromMap(account.toMap()), account);
    });

    test('copies, compares, and hashes predictably', () {
      final copied = account.copyWith(balanceMinorUnits: 150000);
      final unchanged = account.copyWith();

      expect(copied.balanceMinorUnits, 150000);
      expect(copied, isNot(account));
      expect(unchanged, account);
      expect(unchanged.hashCode, account.hashCode);
    });
  });

  group('Category model', () {
    const category = Category(
      id: 'category-1',
      name: 'Groceries',
      iconKey: 'basket',
      colorHex: '#22C55E',
    );

    test('round-trips through a SQLite row map', () {
      expect(Category.fromMap(category.toMap()), category);
    });

    test('copies, compares, and hashes predictably', () {
      final copied = category.copyWith(name: 'Food');
      final unchanged = category.copyWith();

      expect(copied.name, 'Food');
      expect(copied, isNot(category));
      expect(unchanged, category);
      expect(unchanged.hashCode, category.hashCode);
    });
  });

  group('Transaction model', () {
    final timestamp = DateTime.utc(2026, 1, 2, 3, 4);
    final transaction = Transaction(
      id: 'transaction-1',
      accountId: 'account-1',
      categoryId: 'category-1',
      amountMinorUnits: 25000,
      timestamp: timestamp,
      type: TransactionType.expense,
      source: TransactionSource.sms,
      rawText: 'Payment received',
      payee: 'Netflix',
    );

    test('round-trips through a SQLite row map', () {
      expect(Transaction.fromMap(transaction.toMap()), transaction);
    });

    test('copies, compares, and hashes predictably', () {
      final copied = transaction.copyWith(amountMinorUnits: 30000);
      final unchanged = transaction.copyWith();

      expect(copied.amountMinorUnits, 30000);
      expect(copied, isNot(transaction));
      expect(unchanged, transaction);
      expect(unchanged.hashCode, transaction.hashCode);
    });
  });

  group('Budget model', () {
    final startDate = DateTime.utc(2026);
    final budget = Budget(
      id: 'budget-1',
      categoryId: 'category-1',
      allocatedAmountMinorUnits: 100000,
      period: BudgetPeriod.monthly,
      startDate: startDate,
    );

    test('round-trips through a SQLite row map', () {
      expect(Budget.fromMap(budget.toMap()), budget);
    });

    test('round-trips a configured warning share', () {
      final configured = budget.copyWith(warningShare: 0.9);
      final restored = Budget.fromMap(configured.toMap());

      expect(restored.warningShare, 0.9);
      expect(restored, configured);
    });

    test('round-trips a null warning share as null', () {
      final restored = Budget.fromMap(budget.toMap());

      expect(restored.warningShare, isNull);
      expect(budget.toMap()['warning_share'], isNull);
    });

    test('copies, compares, and hashes predictably', () {
      final copied = budget.copyWith(allocatedAmountMinorUnits: 120000);
      final unchanged = budget.copyWith();

      expect(copied.allocatedAmountMinorUnits, 120000);
      expect(copied, isNot(budget));
      expect(unchanged, budget);
      expect(unchanged.hashCode, budget.hashCode);
    });

    test('treats a different warning share as a different budget', () {
      final configured = budget.copyWith(warningShare: 0.75);

      expect(configured, isNot(budget));
      expect(configured.warningShare, 0.75);
      expect(budget.copyWith(warningShare: 0.75).hashCode, configured.hashCode);
    });

    test('copyWith can clear the warning share back to null', () {
      final configured = budget.copyWith(warningShare: 0.9);
      final cleared = configured.copyWith(warningShare: null);

      expect(cleared.warningShare, isNull);
      expect(cleared, budget);
    });
  });
}
