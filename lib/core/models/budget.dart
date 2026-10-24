import 'package:flutter/foundation.dart';

/// The recurrence window covered by a budget.
enum BudgetPeriod {
  /// A budget that repeats every day.
  daily,

  /// A budget that repeats every week.
  weekly,

  /// A budget that repeats every month.
  monthly,

  /// A budget that repeats every year.
  yearly,
}

/// A spending limit assigned to a category for a period.
@immutable
class Budget {
  /// Creates an immutable budget snapshot.
  const new({
    required this.id,
    required this.categoryId,
    required this.allocatedAmountMinorUnits,
    required this.period,
    required this.startDate,
    this.warningShare,
  });

  /// Creates a budget from a SQLite row map.
  factory fromMap(Map<String, Object?> map) {
    return Budget(
      id: map['id']! as String,
      categoryId: map['category_id']! as String,
      allocatedAmountMinorUnits: map['allocated_amount_minor_units']! as int,
      period: BudgetPeriod.values.byName(map['period']! as String),
      startDate: DateTime.fromMillisecondsSinceEpoch(
        map['start_date']! as int,
        isUtc: true,
      ),
      warningShare: map['warning_share'] as double?,
    );
  }

  /// The stable local identifier for the budget.
  final String id;

  /// The identifier of the budgeted category.
  final String categoryId;

  /// The allocated amount in the account currency's minor units.
  final int allocatedAmountMinorUnits;

  /// The recurrence window covered by this budget.
  final BudgetPeriod period;

  /// The UTC date on which the first budget period starts.
  final DateTime startDate;

  /// The share of the budget at which the warning level starts, or null to
  /// use the app default.
  ///
  /// Values are exclusive: 0.9 warns once ninety percent of the budget is
  /// spent. The value must lie strictly between zero and one.
  final double? warningShare;

  /// Sentinel for [copyWith] that distinguishes an omitted warning share from
  /// an explicit reset to null.
  static const Object _unsetWarningShare = Object();

  /// Returns a copy with non-null fields replaced by the supplied values.
  ///
  /// Pass [warningShare] as null to clear a configured threshold back to the
  /// app default.
  Budget copyWith({
    String? id,
    String? categoryId,
    int? allocatedAmountMinorUnits,
    BudgetPeriod? period,
    DateTime? startDate,
    Object? warningShare = _unsetWarningShare,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      allocatedAmountMinorUnits:
          allocatedAmountMinorUnits ?? this.allocatedAmountMinorUnits,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      warningShare: identical(warningShare, _unsetWarningShare)
          ? this.warningShare
          : warningShare as double?,
    );
  }

  /// Converts the budget to a map for SQLite persistence.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'category_id': categoryId,
      'allocated_amount_minor_units': allocatedAmountMinorUnits,
      'period': period.name,
      'start_date': startDate.toUtc().millisecondsSinceEpoch,
      'warning_share': warningShare,
    };
  }

  /// Whether [other] is a budget with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Budget &&
            id == other.id &&
            categoryId == other.categoryId &&
            allocatedAmountMinorUnits == other.allocatedAmountMinorUnits &&
            period == other.period &&
            startDate == other.startDate &&
            warningShare == other.warningShare;
  }

  /// A hash code derived from every budget field.
  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    allocatedAmountMinorUnits,
    period,
    startDate,
    warningShare,
  );
}
