import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';

/// An in-memory [AccountRepository] implementation for development and tests
/// until the encrypted database wiring task lands.
class InMemoryAccountRepository implements AccountRepository {
  /// Creates an in-memory account repository with optional initial accounts.
  new({Map<String, Account> initialAccounts = const <String, Account>{}})
    : _accounts = Map.of(initialAccounts);

  final Map<String, Account> _accounts;

  @override
  Future<List<Account>> list() async => _accounts.values.toList();

  @override
  Future<Account?> get(String id) async => _accounts[id];

  @override
  Future<void> create(Account account) async {
    _accounts[account.id] = account;
  }

  @override
  Future<void> update(Account account) async {
    _accounts[account.id] = account;
  }

  @override
  Future<void> delete(String id) async {
    _accounts.remove(id);
  }

  @override
  Future<void> eraseAll() async {
    _accounts.clear();
  }
}
