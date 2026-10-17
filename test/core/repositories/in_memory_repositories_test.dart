import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/implementations/in_memory_account_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_category_repository.dart';
import 'package:finecho/core/repositories/implementations/in_memory_transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _transaction({required String id, required DateTime timestamp}) {
  return Transaction(
    id: id,
    accountId: 'account-1',
    amountMinorUnits: 1250,
    timestamp: timestamp,
    type: TransactionType.expense,
    source: TransactionSource.manual,
  );
}

void main() {
  test(
    'in-memory transaction repository persists, orders, and deletes',
    () async {
      final repository = InMemoryTransactionRepository();
      final older = _transaction(
        id: 'txn-older',
        timestamp: DateTime.utc(2026, 10),
      );
      final newer = _transaction(
        id: 'txn-newer',
        timestamp: DateTime.utc(2026, 10, 2),
      );

      await repository.create(older);
      await repository.create(newer);

      final listed = await repository.list();
      expect(listed.map((transaction) => transaction.id), <String>[
        'txn-newer',
        'txn-older',
      ]);

      final fetched = await repository.get('txn-older');
      expect(fetched?.id, 'txn-older');

      await repository.update(
        _transaction(id: 'txn-older', timestamp: DateTime.utc(2026, 10, 3)),
      );
      final updated = await repository.get('txn-older');
      expect(updated?.timestamp, DateTime.utc(2026, 10, 3));

      await repository.delete('txn-newer');
      expect(await repository.get('txn-newer'), isNull);
      expect((await repository.list()).length, 1);
    },
  );

  test('in-memory account repository persists and deletes accounts', () async {
    final repository = InMemoryAccountRepository();
    const account = Account(
      id: 'account-1',
      name: 'Cash',
      type: AccountType.cash,
      currency: 'EGP',
      balanceMinorUnits: 50000,
    );

    await repository.create(account);
    expect((await repository.list()).single.id, 'account-1');
    expect((await repository.get('account-1'))?.name, 'Cash');

    await repository.update(account.copyWith(name: 'Wallet cash'));
    expect((await repository.get('account-1'))?.name, 'Wallet cash');

    await repository.update(account.copyWith(archived: true));
    expect((await repository.get('account-1'))?.archived, isTrue);

    await repository.delete('account-1');
    expect(await repository.get('account-1'), isNull);
    expect(await repository.list(), isEmpty);
  });

  test(
    'in-memory category repository persists and deletes categories',
    () async {
      final repository = InMemoryCategoryRepository();
      const category = Category(
        id: 'category-1',
        name: 'Groceries',
        iconKey: 'shopping_cart',
        colorHex: '#FF7759',
      );

      await repository.create(category);
      expect((await repository.list()).single.id, 'category-1');
      expect((await repository.get('category-1'))?.name, 'Groceries');

      await repository.update(category.copyWith(name: 'Food'));
      expect((await repository.get('category-1'))?.name, 'Food');

      await repository.delete('category-1');
      expect(await repository.get('category-1'), isNull);
      expect(await repository.list(), isEmpty);
    },
  );
}
