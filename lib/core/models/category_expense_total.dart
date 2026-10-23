/// Raw expense total for one category over a UTC range.
///
/// A `null` category id marks uncategorized expenses.
class CategoryExpenseTotal {
  /// Creates a category expense total.
  const new({required this.categoryId, required this.totalMinorUnits});

  /// The category the expenses belong to, or `null` when uncategorized.
  final String? categoryId;

  /// Summed expense minor units for the range; transfers are excluded.
  final int totalMinorUnits;
}
