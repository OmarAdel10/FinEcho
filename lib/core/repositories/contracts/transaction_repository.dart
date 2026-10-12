import 'package:finecho/core/models/transaction.dart';

/// Persists and reads FinEcho transactions.
abstract interface class TransactionRepository {
  /// Returns all transactions.
  Future<List<Transaction>> list();

  /// Returns the transaction with [id], or `null` when it does not exist.
  Future<Transaction?> get(String id);

  /// Inserts [transaction].
  Future<void> create(Transaction transaction);

  /// Replaces the stored transaction with the same id as [transaction].
  Future<void> update(Transaction transaction);

  /// Deletes the transaction with [id].
  Future<void> delete(String id);
}
