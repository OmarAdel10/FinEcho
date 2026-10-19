import 'package:flutter/foundation.dart';

/// A category whose current-month spending is far above its recent average.
@immutable
class CategorySpike {
  /// Creates an immutable category spike snapshot.
  const new({
    required this.categoryId,
    required this.name,
    required this.currentExpenseMinorUnits,
    required this.ratio,
  });

  /// The identifier of the category, or `null` when uncategorized.
  final String? categoryId;

  /// The display name of the category.
  final String name;

  /// Expenses recorded this month in minor units.
  final int currentExpenseMinorUnits;

  /// The current expense divided by the prior monthly average.
  final double ratio;

  /// Whether [other] is a category spike with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CategorySpike &&
            categoryId == other.categoryId &&
            name == other.name &&
            currentExpenseMinorUnits == other.currentExpenseMinorUnits &&
            ratio == other.ratio;
  }

  /// A hash code derived from every category spike field.
  @override
  int get hashCode =>
      Object.hash(categoryId, name, currentExpenseMinorUnits, ratio);
}
