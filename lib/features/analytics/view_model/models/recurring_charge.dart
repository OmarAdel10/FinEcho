import 'package:flutter/foundation.dart';

/// An expense that repeats across multiple months of the trailing window.
@immutable
class RecurringCharge {
  /// Creates an immutable recurring charge snapshot.
  const new({
    required this.categoryId,
    required this.name,
    required this.amountMinorUnits,
    required this.monthsSeen,
  });

  /// The identifier of the charge category, or `null` when uncategorized.
  final String? categoryId;

  /// The display name of the charge category.
  final String name;

  /// The amount of the most recent occurrence in minor units.
  final int amountMinorUnits;

  /// The number of consecutive months with a matching charge.
  final int monthsSeen;

  /// Whether [other] is a recurring charge with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RecurringCharge &&
            categoryId == other.categoryId &&
            name == other.name &&
            amountMinorUnits == other.amountMinorUnits &&
            monthsSeen == other.monthsSeen;
  }

  /// A hash code derived from every recurring charge field.
  @override
  int get hashCode =>
      Object.hash(categoryId, name, amountMinorUnits, monthsSeen);
}
