import 'package:flutter/foundation.dart';

/// A per-category expense total for one analytics range.
@immutable
class CategoryTotal {
  /// Creates an immutable category total.
  const new({
    required this.categoryId,
    required this.name,
    required this.expenseMinorUnits,
  });

  /// Creates a category total from a SQLite or serialized row map.
  factory fromMap(Map<String, Object?> map) {
    return CategoryTotal(
      categoryId: map['category_id'] as String?,
      name: map['name'] as String?,
      expenseMinorUnits: map['expense_minor_units']! as int,
    );
  }

  /// The category identifier, or `null` for uncategorized expenses.
  final String? categoryId;

  /// The display category name, or `null` for uncategorized expenses.
  final String? name;

  /// The expense total in the source transaction's minor units.
  final int expenseMinorUnits;

  /// Returns a copy with non-null fields replaced by the supplied values.
  CategoryTotal copyWith({
    String? categoryId,
    String? name,
    int? expenseMinorUnits,
  }) {
    return CategoryTotal(
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      expenseMinorUnits: expenseMinorUnits ?? this.expenseMinorUnits,
    );
  }

  /// Converts the total to a map for analytics serialization.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'category_id': categoryId,
      'name': name,
      'expense_minor_units': expenseMinorUnits,
    };
  }

  /// Whether [other] is a category total with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CategoryTotal &&
            categoryId == other.categoryId &&
            name == other.name &&
            expenseMinorUnits == other.expenseMinorUnits;
  }

  /// A hash code derived from every category total field.
  @override
  int get hashCode => Object.hash(categoryId, name, expenseMinorUnits);
}
