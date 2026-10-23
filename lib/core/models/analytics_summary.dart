import 'package:finecho/core/models/category_total.dart';
import 'package:flutter/foundation.dart';

/// Income, expense, net, and category totals for one UTC time range.
@immutable
class AnalyticsSummary {
  /// Creates an immutable analytics summary.
  ///
  /// Uncategorized expenses remain identifiable by their `null` category id
  /// and name; this avoids inventing a synthetic category key that could be
  /// confused with a real category in the database.
  const new({
    required this.startUtc,
    required this.endUtc,
    required this.totalIncomeMinorUnits,
    required this.totalExpenseMinorUnits,
    required this.categoryExpenseTotals,
    required this.categoryIncomeTotals,
  }) : netAmountMinorUnits = totalIncomeMinorUnits - totalExpenseMinorUnits;

  /// Creates an analytics summary from a serialized row map.
  factory fromMap(Map<String, Object?> map) {
    final categoryMaps = map['category_expense_totals']! as List<Object?>;
    final incomeMaps =
        (map['category_income_totals'] as List<Object?>?) ?? const <Object?>[];

    return AnalyticsSummary(
      startUtc: DateTime.fromMillisecondsSinceEpoch(
        map['start_utc_millis']! as int,
        isUtc: true,
      ),
      endUtc: DateTime.fromMillisecondsSinceEpoch(
        map['end_utc_millis']! as int,
        isUtc: true,
      ),
      totalIncomeMinorUnits: map['total_income_minor_units']! as int,
      totalExpenseMinorUnits: map['total_expense_minor_units']! as int,
      categoryExpenseTotals: categoryMaps
          .map(
            (categoryMap) =>
                CategoryTotal.fromMap(categoryMap! as Map<String, Object?>),
          )
          .toList(growable: false),
      categoryIncomeTotals: incomeMaps
          .map(
            (categoryMap) =>
                CategoryTotal.fromMap(categoryMap! as Map<String, Object?>),
          )
          .toList(growable: false),
    );
  }

  /// The inclusive start of the summarized UTC range.
  final DateTime startUtc;

  /// The exclusive end of the summarized UTC range.
  final DateTime endUtc;

  /// The total income in minor units, excluding transfers.
  final int totalIncomeMinorUnits;

  /// The total expense in minor units, excluding transfers.
  final int totalExpenseMinorUnits;

  /// Income minus expense in minor units, excluding transfers.
  final int netAmountMinorUnits;

  /// Expense totals ordered from highest to lowest amount.
  ///
  /// Uncategorized expenses use a `null` [CategoryTotal.categoryId] and name.
  final List<CategoryTotal> categoryExpenseTotals;

  /// Income totals ordered from highest to lowest amount.
  ///
  /// Uncategorized income uses a `null` [CategoryTotal.categoryId] and name.
  final List<CategoryTotal> categoryIncomeTotals;

  /// Returns a copy with non-null fields replaced by the supplied values.
  AnalyticsSummary copyWith({
    DateTime? startUtc,
    DateTime? endUtc,
    int? totalIncomeMinorUnits,
    int? totalExpenseMinorUnits,
    List<CategoryTotal>? categoryExpenseTotals,
    List<CategoryTotal>? categoryIncomeTotals,
  }) {
    return AnalyticsSummary(
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      totalIncomeMinorUnits:
          totalIncomeMinorUnits ?? this.totalIncomeMinorUnits,
      totalExpenseMinorUnits:
          totalExpenseMinorUnits ?? this.totalExpenseMinorUnits,
      categoryExpenseTotals:
          categoryExpenseTotals ?? this.categoryExpenseTotals,
      categoryIncomeTotals: categoryIncomeTotals ?? this.categoryIncomeTotals,
    );
  }

  /// Converts the summary to a map for analytics serialization.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'start_utc_millis': startUtc.toUtc().millisecondsSinceEpoch,
      'end_utc_millis': endUtc.toUtc().millisecondsSinceEpoch,
      'total_income_minor_units': totalIncomeMinorUnits,
      'total_expense_minor_units': totalExpenseMinorUnits,
      'net_amount_minor_units': netAmountMinorUnits,
      'category_expense_totals': categoryExpenseTotals
          .map((total) => total.toMap())
          .toList(growable: false),
      'category_income_totals': categoryIncomeTotals
          .map((total) => total.toMap())
          .toList(growable: false),
    };
  }

  /// Whether [other] is a summary with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AnalyticsSummary &&
            startUtc == other.startUtc &&
            endUtc == other.endUtc &&
            totalIncomeMinorUnits == other.totalIncomeMinorUnits &&
            totalExpenseMinorUnits == other.totalExpenseMinorUnits &&
            netAmountMinorUnits == other.netAmountMinorUnits &&
            listEquals(categoryExpenseTotals, other.categoryExpenseTotals) &&
            listEquals(categoryIncomeTotals, other.categoryIncomeTotals);
  }

  /// A hash code derived from every analytics summary field.
  @override
  int get hashCode => Object.hash(
    startUtc,
    endUtc,
    totalIncomeMinorUnits,
    totalExpenseMinorUnits,
    netAmountMinorUnits,
    Object.hashAll(categoryExpenseTotals),
    Object.hashAll(categoryIncomeTotals),
  );
}
