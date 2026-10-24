import 'package:finecho/core/models/analytics_account_total.dart';
import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/category_expense_total.dart';
import 'package:finecho/core/models/category_monthly_expense.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/analytics_repository.dart';
import 'package:sqflite_sqlcipher/sqlite_api.dart' show Database;

/// A SQLCipher-backed analytics repository implementation.
class SqfliteAnalyticsRepository implements AnalyticsRepository {
  /// Creates a repository that opens the encrypted database on demand.
  const new({required this.opener});

  /// Opens the encrypted database when a query runs.
  ///
  /// The database is opened lazily so nothing touches secure storage or the
  /// file system before the first query.
  final Future<Database> Function() opener;

  @override
  Future<AnalyticsSummary> summaryForRange({
    required DateTime startUtc,
    required DateTime endUtc,
    String? currency,
  }) async {
    final startMillis = _utcMillis(startUtc, 'startUtc');
    final endMillis = _utcMillis(endUtc, 'endUtc');
    if (startMillis >= endMillis) {
      throw ArgumentError.value(endUtc, 'endUtc', 'must be after startUtc');
    }
    final database = await opener();

    final accountJoin = currency == null
        ? ''
        : 'JOIN accounts AS a ON a.id = account_id';
    final aliasedAccountJoin = currency == null
        ? ''
        : 'JOIN accounts AS a ON a.id = t.account_id';
    final currencyPredicate = currency == null ? '' : 'AND a.currency = ?';
    final currencyArgs = currency == null ? <Object?>[] : <Object?>[currency];

    final totalRows = await database.rawQuery(
      '''
      SELECT
        type,
        COALESCE(SUM(amount_minor_units), 0) AS total_minor_units
      FROM transactions
      $accountJoin
      WHERE timestamp >= ? AND timestamp < ?
        AND type IN (?, ?)
        $currencyPredicate
      GROUP BY type
      ''',
      <Object?>[startMillis, endMillis, 'income', 'expense', ...currencyArgs],
    );

    final categoryRows = await database.rawQuery(
      '''
      SELECT
        t.category_id AS category_id,
        c.name AS name,
        SUM(t.amount_minor_units) AS expense_minor_units
      FROM transactions AS t
      $aliasedAccountJoin
      LEFT JOIN categories AS c ON c.id = t.category_id
      WHERE t.timestamp >= ? AND t.timestamp < ?
        AND t.type = ?
        $currencyPredicate
      GROUP BY t.category_id, c.name
      ORDER BY expense_minor_units DESC, t.category_id IS NULL, t.category_id
      ''',
      <Object?>[startMillis, endMillis, 'expense', ...currencyArgs],
    );

    final categoryTotals = categoryRows
        .map(CategoryTotal.fromMap)
        .toList(growable: false);

    final incomeRows = await database.rawQuery(
      '''
      SELECT
        t.category_id AS category_id,
        c.name AS name,
        0 AS expense_minor_units,
        SUM(t.amount_minor_units) AS income_minor_units
      FROM transactions AS t
      $aliasedAccountJoin
      LEFT JOIN categories AS c ON c.id = t.category_id
      WHERE t.timestamp >= ? AND t.timestamp < ?
        AND t.type = ?
        $currencyPredicate
      GROUP BY t.category_id, c.name
      ORDER BY income_minor_units DESC, t.category_id IS NULL, t.category_id
      ''',
      <Object?>[startMillis, endMillis, 'income', ...currencyArgs],
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

  @override
  Future<List<AnalyticsAccountTotal>> accountTotalsForRange({
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    final startMillis = _utcMillis(startUtc, 'startUtc');
    final endMillis = _utcMillis(endUtc, 'endUtc');
    if (startMillis >= endMillis) {
      throw ArgumentError.value(endUtc, 'endUtc', 'must be after startUtc');
    }
    final database = await opener();

    final rows = await database.rawQuery(
      '''
      SELECT
        t.account_id AS account_id,
        a.currency AS currency,
        t.type AS type,
        COALESCE(SUM(t.amount_minor_units), 0) AS total_minor_units
      FROM transactions AS t
      JOIN accounts AS a ON a.id = t.account_id
      WHERE t.timestamp >= ? AND t.timestamp < ?
        AND t.type IN (?, ?)
      GROUP BY t.account_id, a.currency, t.type
      ''',
      <Object?>[startMillis, endMillis, 'income', 'expense'],
    );

    final incomeByAccount = <String, int>{};
    final expenseByAccount = <String, int>{};
    final accountCurrency = <String, String>{};
    for (final row in rows) {
      final accountId = row['account_id']! as String;
      final total = row['total_minor_units']! as int;
      accountCurrency[accountId] = row['currency']! as String;
      if (row['type'] == 'income') {
        incomeByAccount[accountId] = total;
      } else {
        expenseByAccount[accountId] = total;
      }
    }
    return [
      for (final accountId in <String>{
        ...incomeByAccount.keys,
        ...expenseByAccount.keys,
      })
        AnalyticsAccountTotal(
          accountId: accountId,
          currency: accountCurrency[accountId]!,
          incomeMinorUnits: incomeByAccount[accountId] ?? 0,
          expenseMinorUnits: expenseByAccount[accountId] ?? 0,
        ),
    ];
  }

  @override
  Future<List<CategoryExpenseTotal>> expenseTotalsByCategoryForRange({
    required DateTime startUtc,
    required DateTime endUtc,
    String? currency,
  }) async {
    final startMillis = _utcMillis(startUtc, 'startUtc');
    final endMillis = _utcMillis(endUtc, 'endUtc');
    if (startMillis >= endMillis) {
      throw ArgumentError.value(endUtc, 'endUtc', 'must be after startUtc');
    }
    final database = await opener();

    final accountJoin = currency == null
        ? ''
        : 'JOIN accounts AS a ON a.id = account_id';
    final currencyPredicate = currency == null ? '' : 'AND a.currency = ?';
    final currencyArgs = currency == null ? <Object?>[] : <Object?>[currency];

    final rows = await database.rawQuery(
      '''
      SELECT
        category_id,
        COALESCE(SUM(amount_minor_units), 0) AS total_minor_units
      FROM transactions
      $accountJoin
      WHERE timestamp >= ? AND timestamp < ?
        AND type = 'expense'
        $currencyPredicate
      GROUP BY category_id
      ''',
      <Object?>[startMillis, endMillis, ...currencyArgs],
    );

    return [
      for (final row in rows)
        CategoryExpenseTotal(
          categoryId: row['category_id'] as String?,
          totalMinorUnits: row['total_minor_units']! as int,
        ),
    ];
  }

  @override
  Future<List<CategoryMonthlyExpense>> expenseMonthlyTotalsByCategory({
    required DateTime startUtc,
    required DateTime endUtc,
    String? currency,
  }) async {
    final startMillis = _utcMillis(startUtc, 'startUtc');
    final endMillis = _utcMillis(endUtc, 'endUtc');
    if (startMillis >= endMillis) {
      throw ArgumentError.value(endUtc, 'endUtc', 'must be after startUtc');
    }
    final database = await opener();

    final accountJoin = currency == null
        ? ''
        : 'JOIN accounts AS a ON a.id = account_id';
    final currencyPredicate = currency == null ? '' : 'AND a.currency = ?';
    final currencyArgs = currency == null ? <Object?>[] : <Object?>[currency];

    final rows = await database.rawQuery(
      '''
      SELECT
        category_id,
        CAST(strftime('%Y', timestamp / 1000, 'unixepoch') AS INTEGER) * 12
          + CAST(strftime('%m', timestamp / 1000, 'unixepoch') AS INTEGER)
          AS month_utc,
        COALESCE(SUM(amount_minor_units), 0) AS total_minor_units
      FROM transactions
      $accountJoin
      WHERE timestamp >= ? AND timestamp < ?
        AND type = 'expense'
        $currencyPredicate
      GROUP BY category_id, month_utc
      ''',
      <Object?>[startMillis, endMillis, ...currencyArgs],
    );

    return [
      for (final row in rows)
        CategoryMonthlyExpense(
          categoryId: row['category_id'] as String?,
          monthUtc: row['month_utc']! as int,
          totalMinorUnits: row['total_minor_units']! as int,
        ),
    ];
  }

  @override
  Future<List<Transaction>> expenseTransactionsForRange({
    required DateTime startUtc,
    required DateTime endUtc,
    String? currency,
  }) async {
    final startMillis = _utcMillis(startUtc, 'startUtc');
    final endMillis = _utcMillis(endUtc, 'endUtc');
    if (startMillis >= endMillis) {
      throw ArgumentError.value(endUtc, 'endUtc', 'must be after startUtc');
    }
    final database = await opener();

    final aliasedAccountJoin = currency == null
        ? ''
        : 'JOIN accounts AS a ON a.id = t.account_id';
    final currencyPredicate = currency == null ? '' : 'AND a.currency = ?';
    final currencyArgs = currency == null ? <Object?>[] : <Object?>[currency];

    final rows = await database.rawQuery(
      '''
      SELECT t.*
      FROM transactions AS t
      $aliasedAccountJoin
      WHERE t.timestamp >= ? AND t.timestamp < ?
        AND t.type = ?
        $currencyPredicate
      ORDER BY t.timestamp
      ''',
      <Object?>[startMillis, endMillis, 'expense', ...currencyArgs],
    );
    return rows.map(Transaction.fromMap).toList();
  }
}
