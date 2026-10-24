/// Raw monthly expense total for one category.
///
/// A `null` category id marks uncategorized expenses.
class CategoryMonthlyExpense {
  /// Creates a category monthly expense total.
  const new({
    required this.categoryId,
    required this.monthUtc,
    required this.totalMinorUnits,
  });

  /// The category the expenses belong to, or `null` when uncategorized.
  final String? categoryId;

  /// Calendar month encoded as `year * 12 + month` in UTC.
  final int monthUtc;

  /// Summed expense minor units for the month; transfers are excluded.
  final int totalMinorUnits;
}
