import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/analytics_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';

/// An in-memory [AnalyticsRepository] implementation for development and
/// tests.
///
/// Mirrors the semantics of the SQLCipher-backed implementation, including the
/// half-open UTC range, transfer exclusion, and category total ordering.
class InMemoryAnalyticsRepository implements AnalyticsRepository {
  /// Creates an in-memory analytics repository backed by [transactions] and
  /// [categories].
  const new({
    required TransactionRepository transactions,
    required CategoryRepository categories,
  }) : this._(transactions, categories);

  const new _(this._transactions, this._categories);

  final TransactionRepository _transactions;
  final CategoryRepository _categories;

  @override
  Future<AnalyticsSummary> summaryForRange({
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    final startMillis = _utcMillis(startUtc, 'startUtc');
    final endMillis = _utcMillis(endUtc, 'endUtc');
    if (startMillis >= endMillis) {
      throw ArgumentError.value(endUtc, 'endUtc', 'must be after startUtc');
    }

    final transactions = await _transactions.list();
    final categories = await _categories.list();

    var totalIncomeMinorUnits = 0;
    var totalExpenseMinorUnits = 0;
    final expenseMinorUnitsByCategory = <String?, int>{};

    for (final transaction in transactions) {
      final timestampMillis = transaction.timestamp
          .toUtc()
          .millisecondsSinceEpoch;
      if (timestampMillis < startMillis || timestampMillis >= endMillis) {
        continue;
      }
      if (transaction.type == TransactionType.transfer) {
        continue;
      }
      if (transaction.type == TransactionType.income) {
        totalIncomeMinorUnits += transaction.amountMinorUnits;
        continue;
      }
      totalExpenseMinorUnits += transaction.amountMinorUnits;
      expenseMinorUnitsByCategory.update(
        transaction.categoryId,
        (total) => total + transaction.amountMinorUnits,
        ifAbsent: () => transaction.amountMinorUnits,
      );
    }

    final categoryNames = <String, String>{
      for (final category in categories) category.id: category.name,
    };

    final categoryExpenseTotals =
        expenseMinorUnitsByCategory.entries
            .map(
              (entry) => CategoryTotal(
                categoryId: entry.key,
                name: categoryNames[entry.key],
                expenseMinorUnits: entry.value,
              ),
            )
            .toList(growable: false)
          ..sort(_compareCategoryTotals);

    return AnalyticsSummary(
      startUtc: startUtc,
      endUtc: endUtc,
      totalIncomeMinorUnits: totalIncomeMinorUnits,
      totalExpenseMinorUnits: totalExpenseMinorUnits,
      categoryExpenseTotals: categoryExpenseTotals,
    );
  }

  static int _utcMillis(DateTime timestamp, String parameterName) {
    if (!timestamp.isUtc) {
      throw ArgumentError.value(timestamp, parameterName, 'must be UTC');
    }
    return timestamp.toUtc().millisecondsSinceEpoch;
  }

  static int _compareCategoryTotals(CategoryTotal a, CategoryTotal b) {
    final byExpense = b.expenseMinorUnits.compareTo(a.expenseMinorUnits);
    if (byExpense != 0) {
      return byExpense;
    }
    final aCategoryId = a.categoryId;
    final bCategoryId = b.categoryId;
    if (aCategoryId == null || bCategoryId == null) {
      if (aCategoryId == bCategoryId) {
        return 0;
      }
      return aCategoryId == null ? 1 : -1;
    }
    return aCategoryId.compareTo(bCategoryId);
  }
}
