import 'package:finecho/core/models/analytics_account_total.dart';
import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/category_expense_total.dart';
import 'package:finecho/core/models/category_monthly_expense.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/account_repository.dart';
import 'package:finecho/core/repositories/contracts/analytics_repository.dart';
import 'package:finecho/core/repositories/contracts/category_repository.dart';
import 'package:finecho/core/repositories/contracts/transaction_repository.dart';

/// An in-memory [AnalyticsRepository] implementation for development and
/// tests.
///
/// Mirrors the semantics of the SQLCipher-backed implementation, including the
/// half-open UTC range, transfer exclusion, and category total ordering.
class InMemoryAnalyticsRepository implements AnalyticsRepository {
  /// Creates an in-memory analytics repository backed by [transactions],
  /// [categories], and [accounts].
  const new({
    required TransactionRepository transactions,
    required CategoryRepository categories,
    required AccountRepository accounts,
  }) : this._(transactions, categories, accounts);

  const new _(this._transactions, this._categories, this._accounts);

  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final AccountRepository _accounts;

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

    final currencyByAccount = await _currencyByAccount();
    final transactions = await _transactions.list();
    final categories = await _categories.list();

    var totalIncomeMinorUnits = 0;
    var totalExpenseMinorUnits = 0;
    final expenseMinorUnitsByCategory = <String?, int>{};
    final incomeMinorUnitsByCategory = <String?, int>{};

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
      if (!_matchesCurrency(transaction, currencyByAccount, currency)) {
        continue;
      }
      if (transaction.type == TransactionType.income) {
        totalIncomeMinorUnits += transaction.amountMinorUnits;
        incomeMinorUnitsByCategory.update(
          transaction.categoryId,
          (total) => total + transaction.amountMinorUnits,
          ifAbsent: () => transaction.amountMinorUnits,
        );
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

    final categoryIncomeTotals =
        incomeMinorUnitsByCategory.entries
            .map(
              (entry) => CategoryTotal(
                categoryId: entry.key,
                name: categoryNames[entry.key],
                expenseMinorUnits: 0,
                incomeMinorUnits: entry.value,
              ),
            )
            .toList(growable: false)
          ..sort(_compareCategoryIncomeTotals);

    return AnalyticsSummary(
      startUtc: startUtc,
      endUtc: endUtc,
      totalIncomeMinorUnits: totalIncomeMinorUnits,
      totalExpenseMinorUnits: totalExpenseMinorUnits,
      categoryExpenseTotals: categoryExpenseTotals,
      categoryIncomeTotals: categoryIncomeTotals,
    );
  }

  static int _utcMillis(DateTime timestamp, String parameterName) {
    if (!timestamp.isUtc) {
      throw ArgumentError.value(timestamp, parameterName, 'must be UTC');
    }
    return timestamp.toUtc().millisecondsSinceEpoch;
  }

  static int _compareCategoryIncomeTotals(CategoryTotal a, CategoryTotal b) {
    final byIncome = b.incomeMinorUnits.compareTo(a.incomeMinorUnits);
    if (byIncome != 0) {
      return byIncome;
    }
    return _compareCategoryTotals(a, b);
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

  @override
  Future<List<AnalyticsAccountTotal>> accountTotalsForRange({
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    final startMillis = _utcMillis(startUtc, 'startUtc');
    final endMillis = _utcMillis(endUtc, 'endUtc');
    final currencyByAccount = await _currencyByAccount();
    final incomeByAccount = <String, int>{};
    final expenseByAccount = <String, int>{};
    for (final transaction in await _transactions.list()) {
      if (!_isExpenseOrIncomeInWindow(transaction, startMillis, endMillis)) {
        continue;
      }
      // Mirrors the SQL implementation, which joins the accounts table for
      // the row currency: transactions without a known account are dropped.
      if (!currencyByAccount.containsKey(transaction.accountId)) {
        continue;
      }
      final amount = transaction.amountMinorUnits;
      final accountId = transaction.accountId;
      if (transaction.type == TransactionType.income) {
        incomeByAccount.update(
          accountId,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      } else {
        expenseByAccount.update(
          accountId,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }
    final accountIds = <String>{
      ...incomeByAccount.keys,
      ...expenseByAccount.keys,
    };
    return [
      for (final accountId in accountIds)
        AnalyticsAccountTotal(
          accountId: accountId,
          currency: currencyByAccount[accountId]!,
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
    final currencyByAccount = await _currencyByAccount();
    final totalsByCategory = <String?, int>{};
    for (final transaction in await _transactions.list()) {
      if (transaction.type != TransactionType.expense ||
          !_isInWindow(transaction, startMillis, endMillis)) {
        continue;
      }
      if (!_matchesCurrency(transaction, currencyByAccount, currency)) {
        continue;
      }
      totalsByCategory.update(
        transaction.categoryId,
        (value) => value + transaction.amountMinorUnits,
        ifAbsent: () => transaction.amountMinorUnits,
      );
    }
    return [
      for (final entry in totalsByCategory.entries)
        CategoryExpenseTotal(
          categoryId: entry.key,
          totalMinorUnits: entry.value,
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
    final currencyByAccount = await _currencyByAccount();
    final totalsByCategoryMonth = <String, int>{};
    for (final transaction in await _transactions.list()) {
      if (transaction.type != TransactionType.expense ||
          !_isInWindow(transaction, startMillis, endMillis)) {
        continue;
      }
      if (!_matchesCurrency(transaction, currencyByAccount, currency)) {
        continue;
      }
      final timestamp = transaction.timestamp.toUtc();
      final monthUtc = timestamp.year * 12 + timestamp.month;
      final key = '${transaction.categoryId ?? ''}|$monthUtc';
      totalsByCategoryMonth.update(
        key,
        (value) => value + transaction.amountMinorUnits,
        ifAbsent: () => transaction.amountMinorUnits,
      );
    }
    return [
      for (final entry in totalsByCategoryMonth.entries)
        CategoryMonthlyExpense(
          categoryId: entry.key.split('|').first.isEmpty
              ? null
              : entry.key.split('|').first,
          monthUtc: int.parse(entry.key.split('|').last),
          totalMinorUnits: entry.value,
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
    final currencyByAccount = await _currencyByAccount();
    return [
      for (final transaction in await _transactions.list())
        if (transaction.type == TransactionType.expense &&
            _isInWindow(transaction, startMillis, endMillis) &&
            _matchesCurrency(transaction, currencyByAccount, currency))
          transaction,
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Maps account ids to the ISO currency code each account is denominated
  /// in.
  Future<Map<String, String>> _currencyByAccount() async {
    final accounts = await _accounts.list();
    return <String, String>{
      for (final account in accounts) account.id: account.currency,
    };
  }

  /// Whether [transaction] is denominated in [currency].
  ///
  /// When [currency] is null every transaction matches, mirroring the SQL
  /// implementation, which only joins the accounts table for a non-null
  /// currency filter.
  static bool _matchesCurrency(
    Transaction transaction,
    Map<String, String> currencyByAccount,
    String? currency,
  ) {
    if (currency == null) {
      return true;
    }
    return currencyByAccount[transaction.accountId] == currency;
  }

  static bool _isExpenseOrIncomeInWindow(
    Transaction transaction,
    int startMillis,
    int endMillis,
  ) {
    if (transaction.type == TransactionType.transfer) {
      return false;
    }
    return _isInWindow(transaction, startMillis, endMillis);
  }

  static bool _isInWindow(
    Transaction transaction,
    int startMillis,
    int endMillis,
  ) {
    final timestampMillis = transaction.timestamp
        .toUtc()
        .millisecondsSinceEpoch;
    return timestampMillis >= startMillis && timestampMillis < endMillis;
  }
}
