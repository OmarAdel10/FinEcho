import 'package:finecho/core/models/budget.dart';
import 'package:finecho/features/budget/view_model/models/budget_state.dart';
import 'package:finecho/features/budget/view_model/services/budget_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The budget ViewModel.
class BudgetCubit extends Cubit<BudgetState> {
  /// Creates a budget ViewModel.
  new(this._service) : super(const BudgetState());

  final BudgetService _service;

  /// Loads budgets and categories into state.
  Future<void> load() async {
    emit(state.copyWith(status: BudgetStatus.loading));
    try {
      await _refresh();
    } on Exception {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: BudgetStatus.failure,
          errorMessage: 'Could not load budgets. Please try again.',
          failureSource: BudgetFailureSource.load,
        ),
      );
    }
  }

  /// Validates and saves a new budget. Returns true when saved.
  Future<bool> createBudget({
    required String categoryId,
    required int allocatedAmountMinorUnits,
    required String period,
    required DateTime startDate,
  }) async {
    if (state.status == BudgetStatus.submitting) {
      return false;
    }
    emit(state.copyWith(status: BudgetStatus.submitting));
    try {
      await _service.createBudget(
        categoryId: categoryId,
        allocatedAmountMinorUnits: allocatedAmountMinorUnits,
        period: period,
        startDate: startDate,
      );
      try {
        await _refresh();
      } on Exception {
        if (!isClosed) {
          emit(state.copyWith(status: BudgetStatus.ready));
        }
      }
      return !isClosed;
    } on BudgetValidationException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: BudgetStatus.ready,
          errorMessage: error.message,
          failureSource: BudgetFailureSource.mutation,
        ),
      );
      return false;
    } on Exception {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: BudgetStatus.ready,
          errorMessage: 'Could not save the budget. Please try again.',
          failureSource: BudgetFailureSource.mutation,
        ),
      );
      return false;
    }
  }

  /// Validates and saves edits to [original]. Returns true when saved.
  Future<bool> updateBudget({
    required Budget original,
    required String categoryId,
    required int allocatedAmountMinorUnits,
    required String period,
    required DateTime startDate,
  }) async {
    if (state.status == BudgetStatus.submitting) {
      return false;
    }
    emit(state.copyWith(status: BudgetStatus.submitting));
    try {
      await _service.updateBudget(
        budget: original,
        categoryId: categoryId,
        allocatedAmountMinorUnits: allocatedAmountMinorUnits,
        period: period,
        startDate: startDate,
      );
      try {
        await _refresh();
      } on Exception {
        if (!isClosed) {
          emit(state.copyWith(status: BudgetStatus.ready));
        }
      }
      return !isClosed;
    } on BudgetValidationException catch (error) {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: BudgetStatus.ready,
          errorMessage: error.message,
          failureSource: BudgetFailureSource.mutation,
        ),
      );
      return false;
    } on Exception {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: BudgetStatus.ready,
          errorMessage: 'Could not save the budget. Please try again.',
          failureSource: BudgetFailureSource.mutation,
        ),
      );
      return false;
    }
  }

  /// Deletes the budget with [id]. Returns true when deleted.
  Future<bool> deleteBudget(String id) async {
    if (state.status == BudgetStatus.submitting) {
      return false;
    }
    emit(state.copyWith(status: BudgetStatus.submitting));
    try {
      await _service.deleteBudget(id);
      try {
        await _refresh();
      } on Exception {
        if (!isClosed) {
          emit(state.copyWith(status: BudgetStatus.ready));
        }
      }
      return !isClosed;
    } on Exception {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: BudgetStatus.ready,
          errorMessage: 'Could not delete the budget. Please try again.',
          failureSource: BudgetFailureSource.mutation,
        ),
      );
      return false;
    }
  }

  Future<void> _refresh() async {
    final budgets = await _service.listBudgets();
    final categories = await _service.listCategories();
    if (!isClosed) {
      emit(
        BudgetState(
          status: BudgetStatus.ready,
          budgets: budgets,
          categories: categories,
        ),
      );
    }
  }
}
