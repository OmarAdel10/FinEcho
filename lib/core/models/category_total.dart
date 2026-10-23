import 'package:flutter/foundation.dart';

/// A per-category amount for one analytics range.
@immutable
class CategoryTotal {
  /// Creates an immutable category total.
  const new({
    required this.categoryId,
    required this.name,
    required this.expenseMinorUnits,
    this.incomeMinorUnits = 0,
  });

  /// Creates a category total from a SQLite or serialized row map.
  factory fromMap(Map<String, Object?> map) {
    return CategoryTotal(
      categoryId: map['category_id'] as String?,
      name: map['name'] as String?,
      expenseMinorUnits: map['expense_minor_units']! as int,
      incomeMinorUnits: (map['income_minor_units'] as int?) ?? 0,
    );
  }

  /// The category identifier, or `null` for uncategorized expenses.
  final String? categoryId;

  /// The display category name, or `null` for uncategorized expenses.
  final String? name;

  /// The expense total in the source transaction's minor units.
  final int expenseMinorUnits;

  /// The income total in the source transaction's minor units.
  ///
  /// Income breakdowns carry their amount here, so one model serves both
  /// metrics the way [CategoryTotal] already served expenses.
  final int incomeMinorUnits;

  /// Returns a copy with non-null fields replaced by the supplied values.
  CategoryTotal copyWith({
    String? categoryId,
    String? name,
    int? expenseMinorUnits,
    int? incomeMinorUnits,
  }) {
    return CategoryTotal(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      expenseMinorUnits: expenseMinorUnits ?? this.expenseMinorUnits,
      incomeMinorUnits: incomeMinorUnits ?? this.incomeMinorUnits,
    );
  }

  /// Converts the total to a map for analytics serialization.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'category_id': categoryId,
      'name': name,
      'expense_minor_units': expenseMinorUnits,
      'income_minor_units': incomeMinorUnits,
    };
  }

  /// Whether [other] is a category total with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CategoryTotal &&
            categoryId == other.categoryId &&
            name == other.name &&
            expenseMinorUnits == other.expenseMinorUnits &&
            incomeMinorUnits == other.incomeMinorUnits;
  }

  /// A hash code derived from every category total field.
  @override
  int get hashCode =>
      Object.hash(categoryId, name, expenseMinorUnits, incomeMinorUnits);
}
