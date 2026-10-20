import 'package:flutter/foundation.dart';

/// How much of a budget's allocation is used in its current window.
enum BudgetProgressLevel {
  /// Less than the warning share of the allocation is used.
  normal,

  /// At least the warning share but less than the full allocation is used.
  warning,

  /// The full allocation is used or exceeded.
  exceeded,
}

/// The spending against one budget in the budget's current window.
@immutable
class BudgetProgress {
  /// Creates an immutable budget progress snapshot.
  const new({
    required this.budgetId,
    required this.categoryId,
    required this.categoryName,
    required this.allocatedAmountMinorUnits,
    required this.spentAmountMinorUnits,
    required this.level,
  });

  /// The stable local identifier of the budget.
  final String budgetId;

  /// The identifier of the budgeted category.
  final String categoryId;

  /// The display name of the budgeted category.
  final String categoryName;

  /// The allocated amount in minor units.
  final int allocatedAmountMinorUnits;

  /// The spent amount in minor units.
  final int spentAmountMinorUnits;

  /// The warning level for the current spending.
  final BudgetProgressLevel level;

  /// The spent share of the allocation between 0 and beyond 1.
  double get usedRatio {
    if (allocatedAmountMinorUnits <= 0) {
      return spentAmountMinorUnits > 0 ? 1 : 0;
    }
    return spentAmountMinorUnits / allocatedAmountMinorUnits;
  }

  /// Whether [other] is a budget progress with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BudgetProgress &&
            budgetId == other.budgetId &&
            categoryId == other.categoryId &&
            categoryName == other.categoryName &&
            allocatedAmountMinorUnits == other.allocatedAmountMinorUnits &&
            spentAmountMinorUnits == other.spentAmountMinorUnits &&
            level == other.level;
  }

  /// A hash code derived from every budget progress field.
  @override
  int get hashCode => Object.hash(
    budgetId,
    categoryId,
    categoryName,
    allocatedAmountMinorUnits,
    spentAmountMinorUnits,
    level,
  );
}
