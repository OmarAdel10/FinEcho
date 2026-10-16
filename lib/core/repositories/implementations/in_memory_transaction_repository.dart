import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';

/// An in-memory [TransactionRepository] implementation for development and
/// tests until the encrypted database wiring task lands.
class InMemoryTransactionRepository implements TransactionRepository {
  /// Creates an empty in-memory transaction repository.
  new({
    Map<String, Transaction> initialTransactions =
        const <String, Transaction>{},
  }) : _transactions = Map.of(initialTransactions);

  final Map<String, Transaction> _transactions;

  @override
  Future<List<Transaction>> list() async {
    final transactions = _transactions.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return transactions;
  }

  @override
  Future<Transaction?> get(String id) async => _transactions[id];

  @override
  Future<void> create(Transaction transaction) async {
    _transactions[transaction.id] = transaction;
  }

  @override
  Future<void> update(Transaction transaction) async {
    _transactions[transaction.id] = transaction;
  }

  @override
  Future<void> delete(String id) async {
    _transactions.remove(id);
  }
}
