import 'package:finecho/core/models/account.dart';

/// Persists and reads FinEcho accounts.
abstract interface class AccountRepository {
  /// Returns all accounts.
  Future<List<Account>> list();

  /// Returns the account with [id], or `null` when it does not exist.
  Future<Account?> get(String id);

  /// Inserts [account].
  Future<void> create(Account account);

  /// Replaces the stored account that has the same id as [account].
  Future<void> update(Account account);

  /// Deletes the account with [id].
  Future<void> delete(String id);

  /// Erases all accounts.
  Future<void> eraseAll();
}
