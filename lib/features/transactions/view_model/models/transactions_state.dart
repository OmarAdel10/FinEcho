import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:flutter/foundation.dart' hide Category;

/// The lifecycle of the transactions ViewModel.
enum TransactionsStatus {
  /// Initial state before data is loaded.
  loading,

  /// Data is ready to render.
  ready,

  /// A mutation is being persisted.
  submitting,

  /// The last operation failed.
  failure,
}

/// Immutable state rendered by transaction views.
@immutable
class TransactionsState {
  /// Creates an immutable transactions state.
  const new({
    this.status = TransactionsStatus.loading,
    this.transactions = const <Transaction>[],
    this.accounts = const <Account>[],
    this.categories = const <Category>[],
    this.errorMessage,
  });

  /// The current ViewModel lifecycle status.
  final TransactionsStatus status;

  /// The transactions available for display, newest first.
  final List<Transaction> transactions;

  /// The accounts available for transaction selection.
  final List<Account> accounts;

  /// The categories available for transaction selection.
  final List<Category> categories;

  /// A user-facing error, when present.
  final String? errorMessage;

  /// Whether the ViewModel is waiting for a mutation to persist.
  bool get isSubmitting => status == TransactionsStatus.submitting;

  /// Returns a copy with the supplied non-null fields replaced.
  TransactionsState copyWith({
    TransactionsStatus? status,
    List<Transaction>? transactions,
    List<Account>? accounts,
    List<Category>? categories,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
