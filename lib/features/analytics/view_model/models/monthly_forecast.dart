import 'package:flutter/foundation.dart';

/// A projection of the current calendar month's spending.
@immutable
class MonthlyForecast {
  /// Creates an immutable monthly forecast snapshot.
  const new({
    required this.monthStartUtc,
    required this.monthEndUtc,
    required this.elapsedDays,
    required this.daysInMonth,
    required this.expenseSoFarMinorUnits,
    required this.projectedExpenseMinorUnits,
  });

  /// The inclusive UTC start of the forecast month.
  final DateTime monthStartUtc;

  /// The exclusive UTC end of the forecast month.
  final DateTime monthEndUtc;

  /// The number of elapsed days in the forecast month.
  final int elapsedDays;

  /// The total number of days in the forecast month.
  final int daysInMonth;

  /// Expenses recorded so far this month in minor units.
  final int expenseSoFarMinorUnits;

  /// The projected month-end expenses in minor units.
  final int projectedExpenseMinorUnits;

  /// Whether [other] is a monthly forecast with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MonthlyForecast &&
            monthStartUtc == other.monthStartUtc &&
            monthEndUtc == other.monthEndUtc &&
            elapsedDays == other.elapsedDays &&
            daysInMonth == other.daysInMonth &&
            expenseSoFarMinorUnits == other.expenseSoFarMinorUnits &&
            projectedExpenseMinorUnits == other.projectedExpenseMinorUnits;
  }

  /// A hash code derived from every monthly forecast field.
  @override
  int get hashCode => Object.hash(
    monthStartUtc,
    monthEndUtc,
    elapsedDays,
    daysInMonth,
    expenseSoFarMinorUnits,
    projectedExpenseMinorUnits,
  );
}
