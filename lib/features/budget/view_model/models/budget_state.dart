import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
import 'package:flutter/foundation.dart' hide Category;

/// The lifecycle of the budget ViewModel.
enum BudgetStatus {
  /// Initial state before data is loaded.
  loading,

  /// Data is ready to render.
  ready,

  /// A mutation is being persisted.
  submitting,

  /// The last operation failed.
  failure,
}

/// The operation that produced a failed ViewModel state.
enum BudgetFailureSource {
  /// Loading the initial list failed.
  load,

  /// A create, update, or delete mutation failed.
  mutation,
}

/// Immutable state rendered by budget views.
@immutable
class BudgetState {
  /// Creates an immutable budget state.
  const new({
    this.status = BudgetStatus.loading,
    this.budgets = const <Budget>[],
    this.categories = const <Category>[],
    this.errorMessage,
    this.failureSource = BudgetFailureSource.load,
  });

  /// The current ViewModel lifecycle status.
  final BudgetStatus status;

  /// The budgets available for display.
  final List<Budget> budgets;

  /// The categories available for budget selection.
  final List<Category> categories;

  /// A user-facing error, when present.
  final String? errorMessage;

  /// The operation responsible for the current failure.
  final BudgetFailureSource failureSource;

  /// Whether the ViewModel is waiting for a mutation to persist.
  bool get isSubmitting => status == BudgetStatus.submitting;

  /// Returns a copy with the supplied non-null fields replaced.
  BudgetState copyWith({
    BudgetStatus? status,
    List<Budget>? budgets,
    List<Category>? categories,
    String? errorMessage,
    BudgetFailureSource? failureSource,
    bool clearErrorMessage = false,
  }) {
    return BudgetState(
      status: status ?? this.status,
      budgets: budgets ?? this.budgets,
      categories: categories ?? this.categories,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      failureSource: failureSource ?? this.failureSource,
    );
  }
}
