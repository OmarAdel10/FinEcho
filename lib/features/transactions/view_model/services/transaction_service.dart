import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';

/// Thrown when a transaction change fails validation.
class TransactionValidationException implements Exception {
  /// Creates a validation exception with a user-facing [message].
  const new(this.message);

  /// The user-facing validation message.
  final String message;

  @override
  String toString() => message;
}

/// Validates and coordinates FinEcho transaction persistence.
class TransactionService {
  /// Creates a transaction service.
  const new({
    required TransactionRepository transactions,
    required AccountRepository accounts,
    required CategoryRepository categories,
    DateTime Function()? now,
    String Function()? newId,
  }) : this._(
         transactions,
         accounts,
         categories,
         now ?? DateTime.now,
         newId ?? _defaultNewId,
       );

  const new _(
    this._transactions,
    this._accounts,
    this._categories,
    this._now,
    this._newId,
  );

  final TransactionRepository _transactions;
  final AccountRepository _accounts;
  final CategoryRepository _categories;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Returns all transactions, newest first.
  Future<List<Transaction>> listTransactions() async {
    final list = await _transactions.list();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// Returns all accounts.
  Future<List<Account>> listAccounts() => _accounts.list();

  /// Returns all categories.
  Future<List<Category>> listCategories() => _categories.list();

  /// Validates and persists a new manual transaction.
  ///
  /// The manual-entry note is stored in [Transaction.rawText] until a
  /// dedicated note column lands with the later draft-status schema migration.
  Future<Transaction> addTransaction({
    required String accountId,
    required TransactionType type,
    required int amountMinorUnits,
    String? categoryId,
    String? note,
    DateTime? timestamp,
  }) async {
    await _validate(
      accountId: accountId,
      categoryId: categoryId,
      amountMinorUnits: amountMinorUnits,
    );
    final transaction = Transaction(
      id: _newId(),
      accountId: accountId,
      categoryId: categoryId,
      amountMinorUnits: amountMinorUnits,
      timestamp: (timestamp ?? _now()).toUtc(),
      type: type,
      source: TransactionSource.manual,
      rawText: note,
    );
    await _transactions.create(transaction);
    return transaction;
  }

  /// Validates and persists edits to [original].
  ///
  /// The edited note is stored in [Transaction.rawText] until a dedicated
  /// note column lands with the later draft-status schema migration.
  Future<Transaction> updateTransaction({
    required Transaction original,
    required String accountId,
    required TransactionType type,
    required int amountMinorUnits,
    String? categoryId,
    String? note,
    DateTime? timestamp,
  }) async {
    await _validate(
      accountId: accountId,
      categoryId: categoryId,
      amountMinorUnits: amountMinorUnits,
    );
    final transaction = Transaction(
      id: original.id,
      accountId: accountId,
      categoryId: categoryId,
      amountMinorUnits: amountMinorUnits,
      timestamp: (timestamp ?? original.timestamp).toUtc(),
      type: type,
      source: original.source,
      rawText: note,
    );
    await _transactions.update(transaction);
    return transaction;
  }

  /// Deletes the transaction with [id].
  Future<void> deleteTransaction(String id) => _transactions.delete(id);

  static String _defaultNewId() {
    return 'txn-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _validate({
    required String accountId,
    required String? categoryId,
    required int amountMinorUnits,
  }) async {
    if (amountMinorUnits <= 0) {
      throw const TransactionValidationException(
        'Enter an amount greater than zero.',
      );
    }

    final account = await _accounts.get(accountId);
    if (account == null) {
      throw const TransactionValidationException('Choose a valid account.');
    }

    if (categoryId == null) {
      return;
    }
    final category = await _categories.get(categoryId);
    if (category == null) {
      throw const TransactionValidationException('Choose a valid category.');
    }
  }
}
