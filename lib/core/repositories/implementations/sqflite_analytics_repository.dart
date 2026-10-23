import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/core/repositories/contracts/analytics_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed analytics repository implementation.
class SqfliteAnalyticsRepository implements AnalyticsRepository {
  /// Creates a repository backed by the supplied SQLite database.
  const new(this._database);

  final Database _database;

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

    final totalRows = await _database.rawQuery(
      '''
      SELECT
        type,
        COALESCE(SUM(amount_minor_units), 0) AS total_minor_units
      FROM transactions
      WHERE timestamp >= ? AND timestamp < ?
        AND type IN (?, ?)
      GROUP BY type
      ''',
      <Object?>[startMillis, endMillis, 'income', 'expense'],
    );

    final categoryRows = await _database.rawQuery(
      '''
      SELECT
        t.category_id AS category_id,
        c.name AS name,
        SUM(t.amount_minor_units) AS expense_minor_units
      FROM transactions AS t
      LEFT JOIN categories AS c ON c.id = t.category_id
      WHERE t.timestamp >= ? AND t.timestamp < ?
        AND t.type = ?
      GROUP BY t.category_id, c.name
      ORDER BY expense_minor_units DESC, t.category_id IS NULL, t.category_id
      ''',
      <Object?>[startMillis, endMillis, 'expense'],
    );

    final categoryTotals = categoryRows
        .map(CategoryTotal.fromMap)
        .toList(growable: false);

    final incomeRows = await _database.rawQuery(
      '''
      SELECT
        t.category_id AS category_id,
        c.name AS name,
        0 AS expense_minor_units,
        SUM(t.amount_minor_units) AS income_minor_units
      FROM transactions AS t
      LEFT JOIN categories AS c ON c.id = t.category_id
      WHERE t.timestamp >= ? AND t.timestamp < ?
        AND t.type = ?
      GROUP BY t.category_id, c.name
      ORDER BY income_minor_units DESC, t.category_id IS NULL, t.category_id
      ''',
      <Object?>[startMillis, endMillis, 'income'],
    );

    final categoryIncomeTotals = incomeRows
        .map(CategoryTotal.fromMap)
        .toList(growable: false);

    return AnalyticsSummary(
      startUtc: startUtc,
      endUtc: endUtc,
      totalIncomeMinorUnits: _totalForType(totalRows, 'income'),
      totalExpenseMinorUnits: _totalForType(totalRows, 'expense'),
      categoryExpenseTotals: categoryTotals,
      categoryIncomeTotals: categoryIncomeTotals,
    );
  }

  static int _utcMillis(DateTime timestamp, String parameterName) {
    if (!timestamp.isUtc) {
      throw ArgumentError.value(timestamp, parameterName, 'must be UTC');
    }
    return timestamp.toUtc().millisecondsSinceEpoch;
  }

  static int _totalForType(List<Map<String, Object?>> rows, String type) {
    for (final row in rows) {
      if (row['type'] == type) {
        return row['total_minor_units']! as int;
      }
    }
    return 0;
  }
}
