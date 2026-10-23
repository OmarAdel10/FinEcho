import 'dart:async';

import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';
import 'package:finecho/features/transactions/view_model/services/transaction_service.dart';

/// An in-memory [TransactionRepository] fake for transaction tests.
class FakeTransactionRepository implements TransactionRepository {
  /// Creates a fake repository with optional initial transactions.
  new({Map<String, Transaction> initialTransactions = const {}})
    : _transactions = Map<String, Transaction>.of(initialTransactions);

  final Map<String, Transaction> _transactions;

  /// Every id passed to [create], in persistence order.
  final List<String> createdIds = <String>[];

  /// Every id passed to [update], in persistence order.
  final List<String> updatedIds = <String>[];

  /// Every id passed to [delete], in persistence order.
  final List<String> deletedIds = <String>[];

  /// Errors to throw from [list].
  Exception? listError;

  /// Errors to throw from [create].
  Exception? createError;

  /// Errors to throw from [update].
  Exception? updateError;

  /// Errors to throw from [delete].
  Exception? deleteError;

  /// An optional gate that keeps the next [create] call pending.
  Completer<void>? createGate;

  /// The current transactions, keyed by id.
  Map<String, Transaction> get transactions => Map.unmodifiable(_transactions);

  @override
  Future<List<Transaction>> list() async {
    final error = listError;
    if (error != null) {
      throw error;
    }
    return _transactions.values.toList();
  }

  @override
  Future<Transaction?> get(String id) async => _transactions[id];

  @override
  Future<void> create(Transaction transaction) async {
    final gate = createGate;
    if (gate != null) {
      await gate.future;
    }
    final error = createError;
    if (error != null) {
      throw error;
    }
    createdIds.add(transaction.id);
    _transactions[transaction.id] = transaction;
  }

  @override
  Future<void> update(Transaction transaction) async {
    final error = updateError;
    if (error != null) {
      throw error;
    }
    updatedIds.add(transaction.id);
    _transactions[transaction.id] = transaction;
  }

  @override
  Future<void> delete(String id) async {
    final error = deleteError;
    if (error != null) {
      throw error;
    }
    deletedIds.add(id);
    _transactions.remove(id);
  }

  @override
  Future<void> eraseAll() async {
    _transactions.clear();
  }
}

/// An in-memory [AccountRepository] fake for transaction tests.
class FakeAccountRepository implements AccountRepository {
  /// Creates a fake repository with optional initial accounts.
  new({Map<String, Account> initialAccounts = const {}})
    : _accounts = Map<String, Account>.of(initialAccounts);

  final Map<String, Account> _accounts;

  /// Every id passed to [create], in persistence order.
  final List<String> createdIds = <String>[];

  /// Every id passed to [update], in persistence order.
  final List<String> updatedIds = <String>[];

  /// Every id passed to [delete], in persistence order.
  final List<String> deletedIds = <String>[];

  /// Errors to throw from [list].
  Exception? listError;

  /// Errors to throw from [create].
  Exception? createError;

  /// Errors to throw from [update].
  Exception? updateError;

  /// Errors to throw from [delete].
  Exception? deleteError;

  /// The current accounts, keyed by id.
  Map<String, Account> get accounts => Map.unmodifiable(_accounts);

  @override
  Future<List<Account>> list() async {
    final error = listError;
    if (error != null) {
      throw error;
    }
    return _accounts.values.toList();
  }

  @override
  Future<Account?> get(String id) async => _accounts[id];

  @override
  Future<void> create(Account account) async {
    final error = createError;
    if (error != null) {
      throw error;
    }
    createdIds.add(account.id);
    _accounts[account.id] = account;
  }

  @override
  Future<void> update(Account account) async {
    final error = updateError;
    if (error != null) {
      throw error;
    }
    updatedIds.add(account.id);
    _accounts[account.id] = account;
  }

  @override
  Future<void> delete(String id) async {
    final error = deleteError;
    if (error != null) {
      throw error;
    }
    deletedIds.add(id);
    _accounts.remove(id);
  }

  @override
  Future<void> eraseAll() async {
    _accounts.clear();
  }
}

/// An in-memory [CategoryRepository] fake for transaction tests.
class FakeCategoryRepository implements CategoryRepository {
  /// Creates a fake repository with optional initial categories.
  new({Map<String, Category> initialCategories = const {}})
    : _categories = Map<String, Category>.of(initialCategories);

  final Map<String, Category> _categories;

  /// Every id passed to [create], in persistence order.
  final List<String> createdIds = <String>[];

  /// Every id passed to [update], in persistence order.
  final List<String> updatedIds = <String>[];

  /// Every id passed to [delete], in persistence order.
  final List<String> deletedIds = <String>[];

  /// Errors to throw from [list].
  Exception? listError;

  /// Errors to throw from [create].
  Exception? createError;

  /// Errors to throw from [update].
  Exception? updateError;

  /// Errors to throw from [delete].
  Exception? deleteError;

  /// The current categories, keyed by id.
  Map<String, Category> get categories => Map.unmodifiable(_categories);

  @override
  Future<List<Category>> list() async {
    final error = listError;
    if (error != null) {
      throw error;
    }
    return _categories.values.toList();
  }

  @override
  Future<Category?> get(String id) async => _categories[id];

  @override
  Future<void> create(Category category) async {
    final error = createError;
    if (error != null) {
      throw error;
    }
    createdIds.add(category.id);
    _categories[category.id] = category;
  }

  @override
  Future<void> update(Category category) async {
    final error = updateError;
    if (error != null) {
      throw error;
    }
    updatedIds.add(category.id);
    _categories[category.id] = category;
  }

  @override
  Future<void> delete(String id) async {
    final error = deleteError;
    if (error != null) {
      throw error;
    }
    deletedIds.add(id);
    _categories.remove(id);
  }

  @override
  Future<void> eraseAll() async {
    _categories.clear();
  }
}

/// A bundle of transaction fakes and the service built from them.
class TransactionsTestHarness {
  /// Creates the fake repository bundle and its deterministic service.
  new({
    Map<String, Transaction> initialTransactions = const {},
    Map<String, Account> initialAccounts = const {},
    Map<String, Category> initialCategories = const {},
    DateTime Function()? now,
    String Function()? newId,
  }) : transactionRepository = FakeTransactionRepository(
         initialTransactions: initialTransactions,
       ),
       accountRepository = FakeAccountRepository(
         initialAccounts: initialAccounts,
       ),
       categoryRepository = FakeCategoryRepository(
         initialCategories: initialCategories,
       ) {
    service = TransactionService(
      transactions: transactionRepository,
      accounts: accountRepository,
      categories: categoryRepository,
      now: now,
      newId: newId,
    );
  }

  /// The fake transaction store.
  final FakeTransactionRepository transactionRepository;

  /// The fake account store.
  final FakeAccountRepository accountRepository;

  /// The fake category store.
  final FakeCategoryRepository categoryRepository;

  /// The service under test, backed by the fakes.
  late final TransactionService service;
}
