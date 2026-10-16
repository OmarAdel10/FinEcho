import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/transactions/view_model/models/transactions_state.dart';
import 'package:finecho/features/transactions/view_model/services/transaction_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The transactions ViewModel.
class TransactionsCubit extends Cubit<TransactionsState> {
  /// Creates a transactions ViewModel.
  new(this._service) : super(const TransactionsState());

  final TransactionService _service;

  /// Loads transactions, accounts, and categories into state.
  Future<void> load() async {
    emit(state.copyWith(status: TransactionsStatus.loading));
    try {
      await _refresh();
    } on Exception {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: TransactionsStatus.failure,
          errorMessage: 'Could not load transactions. Please try again.',
        ),
      );
    }
  }

  /// Validates and saves a new transaction. Returns true when saved.
  Future<bool> addTransaction({
    required String accountId,
    required TransactionType type,
    required int amountMinorUnits,
    String? categoryId,
    String? note,
  }) async {
    if (state.status == TransactionsStatus.submitting) {
      return false;
    }
    emit(state.copyWith(status: TransactionsStatus.submitting));
    try {
      await _service.addTransaction(
        accountId: accountId,
        type: type,
        amountMinorUnits: amountMinorUnits,
        categoryId: categoryId,
        note: note,
      );
      await _refresh();
      return !isClosed;
    } on TransactionValidationException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TransactionsStatus.failure,
          errorMessage: error.message,
        ),
      );
      return false;
    } on Exception {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TransactionsStatus.failure,
          errorMessage: 'Could not save the transaction. Please try again.',
        ),
      );
      return false;
    }
  }

  /// Validates and saves edits to [original]. Returns true when saved.
  Future<bool> updateTransaction({
    required Transaction original,
    required String accountId,
    required TransactionType type,
    required int amountMinorUnits,
    String? categoryId,
    String? note,
  }) async {
    if (state.status == TransactionsStatus.submitting) {
      return false;
    }
    emit(state.copyWith(status: TransactionsStatus.submitting));
    try {
      await _service.updateTransaction(
        original: original,
        accountId: accountId,
        type: type,
        amountMinorUnits: amountMinorUnits,
        categoryId: categoryId,
        note: note,
      );
      await _refresh();
      return !isClosed;
    } on TransactionValidationException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TransactionsStatus.failure,
          errorMessage: error.message,
        ),
      );
      return false;
    } on Exception {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TransactionsStatus.failure,
          errorMessage: 'Could not save the transaction. Please try again.',
        ),
      );
      return false;
    }
  }

  /// Deletes the transaction with [id]. Returns true when deleted.
  Future<bool> deleteTransaction(String id) async {
    if (state.status == TransactionsStatus.submitting) {
      return false;
    }
    emit(state.copyWith(status: TransactionsStatus.submitting));
    try {
      await _service.deleteTransaction(id);
      await _refresh();
      return !isClosed;
    } on TransactionValidationException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TransactionsStatus.failure,
          errorMessage: error.message,
        ),
      );
      return false;
    } on Exception {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: TransactionsStatus.failure,
          errorMessage: 'Could not delete the transaction. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<void> _refresh() async {
    final transactions = await _service.listTransactions();
    final accounts = await _service.listAccounts();
    final categories = await _service.listCategories();
    if (!isClosed) {
      emit(
        TransactionsState(
          status: TransactionsStatus.ready,
          transactions: transactions,
          accounts: accounts,
          categories: categories,
        ),
      );
    }
  }
}
