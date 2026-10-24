import 'dart:async';

import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/analytics_account_total.dart';
import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/category_expense_total.dart';
import 'package:finecho/core/models/category_monthly_expense.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/core/repositories/contracts/analytics_repository.dart';
import 'package:finecho/features/analytics/view_model/services/analytics_service.dart';

import '../budget/fake_budget_repositories.dart';
import '../transactions/fake_transaction_repositories.dart';

/// The default clock used by analytics tests: 2026-10-15T12:00:00Z.
final DateTime analyticsTestNow = DateTime.utc(2026, 10, 15, 12);

/// An in-memory [AnalyticsRepository] fake for analytics tests.
class FakeAnalyticsRepository implements AnalyticsRepository {
  /// Creates a fake analytics repository.
  new({
    AnalyticsSummary? summary,
    this.onSummary,
    this.error,
    this.transactionsSource,
  }) : summary = summary ?? _emptySummary;

  /// The transactions the aggregate queries read, or empty when unset.
  Future<List<Transaction>> Function()? transactionsSource;

  /// The accounts consulted for currency filtering, or empty when unset.
  Future<List<Account>> Function()? accountsSource;

  /// The currency reported for activity whose account is not seeded.
  ///
  /// Matches the EGP fixtures used across the analytics tests.
  static const String _unknownAccountCurrency = 'EGP';

  /// The summary returned when [onSummary] is not set.
  final AnalyticsSummary summary;

  /// Every currency passed to [summaryForRange], in request order.
  final List<String?> requestedCurrencies = [];

  /// Builds a summary for each requested range when set.
  final AnalyticsSummary Function(DateTime startUtc, DateTime endUtc)?
  onSummary;

  /// An error to throw from [summaryForRange].
  Exception? error;

  /// Keeps the next [summaryForRange] call pending while set.
  Completer<void>? gate;

  /// Every range passed to [summaryForRange], in request order.
  final List<(DateTime, DateTime)> requestedRanges = [];

  @override
  Future<AnalyticsSummary> summaryForRange({
    required DateTime startUtc,
    required DateTime endUtc,
    String? currency,
  }) async {
    if (!startUtc.isBefore(endUtc)) {
      throw ArgumentError.value(endUtc, 'endUtc', 'must be after startUtc');
    }
    requestedRanges.add((startUtc, endUtc));
    requestedCurrencies.add(currency);
    final gate = this.gate;
    if (gate != null) {
      await gate.future;
    }
    final error = this.error;
    if (error != null) {
      throw error;
    }
    final onSummary = this.onSummary;
    if (onSummary != null) {
      return onSummary(startUtc, endUtc);
    }
    return summary;
  }

  List<Transaction> _windowExpenses(
    DateTime startUtc,
    DateTime endUtc,
    List<Transaction> transactions,
    Map<String, String> currencyByAccount,
    String? currency,
  ) {
    final startMillis = startUtc.millisecondsSinceEpoch;
    final endMillis = endUtc.millisecondsSinceEpoch;
    final expenses = transactions.where((transaction) {
      if (transaction.type != TransactionType.expense) {
        return false;
      }
      if (currency != null &&
          currencyByAccount[transaction.accountId] != currency) {
        return false;
      }
      final millis = transaction.timestamp.toUtc().millisecondsSinceEpoch;
      return millis >= startMillis && millis < endMillis;
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return expenses;
  }

  Future<List<Transaction>> _transactions() {
    final source = transactionsSource;
    if (source == null) {
      return Future.value(const <Transaction>[]);
    }
    return source();
  }

  Future<Map<String, String>> _currencyByAccount() async {
    final source = accountsSource;
    if (source == null) {
      return const <String, String>{};
    }
    return {for (final account in await source()) account.id: account.currency};
  }

  @override
  Future<List<AnalyticsAccountTotal>> accountTotalsForRange({
    required DateTime startUtc,
    required DateTime endUtc,
  }) async {
    final startMillis = startUtc.millisecondsSinceEpoch;
    final endMillis = endUtc.millisecondsSinceEpoch;
    final currencyByAccount = await _currencyByAccount();
    final incomeByAccount = <String, int>{};
    final expenseByAccount = <String, int>{};
    for (final transaction in await _transactions()) {
      if (transaction.type == TransactionType.transfer) {
        continue;
      }
      final millis = transaction.timestamp.toUtc().millisecondsSinceEpoch;
      if (millis < startMillis || millis >= endMillis) {
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
    return [
      for (final accountId in <String>{
        ...incomeByAccount.keys,
        ...expenseByAccount.keys,
      })
        AnalyticsAccountTotal(
          accountId: accountId,
          currency: currencyByAccount[accountId] ?? _unknownAccountCurrency,
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
    final totals = <String?, int>{};
    for (final transaction in _windowExpenses(
      startUtc,
      endUtc,
      await _transactions(),
      await _currencyByAccount(),
      currency,
    )) {
      totals.update(
        transaction.categoryId,
        (value) => value + transaction.amountMinorUnits,
        ifAbsent: () => transaction.amountMinorUnits,
      );
    }
    return [
      for (final entry in totals.entries)
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
    final totals = <String, int>{};
    for (final transaction in _windowExpenses(
      startUtc,
      endUtc,
      await _transactions(),
      await _currencyByAccount(),
      currency,
    )) {
      final timestamp = transaction.timestamp.toUtc();
      final monthUtc = timestamp.year * 12 + timestamp.month;
      final key = '${transaction.categoryId ?? ''}|$monthUtc';
      totals.update(
        key,
        (value) => value + transaction.amountMinorUnits,
        ifAbsent: () => transaction.amountMinorUnits,
      );
    }
    return [
      for (final entry in totals.entries)
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
    final transactions = await _transactions();
    return _windowExpenses(
      startUtc,
      endUtc,
      transactions,
      await _currencyByAccount(),
      currency,
    );
  }
}

/// A zeroed summary for tests that do not provide one.
final AnalyticsSummary _emptySummary = AnalyticsSummary(
  startUtc: DateTime.utc(2000),
  endUtc: DateTime.utc(2000, 1, 2),
  totalIncomeMinorUnits: 0,
  totalExpenseMinorUnits: 0,
  categoryExpenseTotals: const [],
  categoryIncomeTotals: const [],
);

/// A bundle of analytics fakes and the service built from them.
class AnalyticsTestHarness {
  /// Creates the fake repository bundle and its deterministic service.
  ///
  /// The service clock defaults to [analyticsTestNow].
  new({
    Map<String, Transaction> initialTransactions = const {},
    Map<String, Account> initialAccounts = const {},
    Map<String, Category> initialCategories = const {},
    Map<String, Budget> initialBudgets = const {},
    AnalyticsSummary Function(DateTime startUtc, DateTime endUtc)? onSummary,
    DateTime Function()? now,
    Duration? localUtcOffset,
  }) : analyticsRepository = FakeAnalyticsRepository(onSummary: onSummary),
       transactionRepository = FakeTransactionRepository(
         initialTransactions: initialTransactions,
       ),
       accountRepository = FakeAccountRepository(
         initialAccounts: initialAccounts,
       ),
       categoryRepository = FakeCategoryRepository(
         initialCategories: initialCategories,
       ),
       budgetRepository = FakeBudgetRepository(initialBudgets: initialBudgets) {
    analyticsRepository.transactionsSource = () =>
        Future.value(transactionRepository.list());
    analyticsRepository.accountsSource = () =>
        Future.value(accountRepository.list());
    service = AnalyticsService(
      analytics: analyticsRepository,
      accounts: accountRepository,
      budgets: budgetRepository,
      categories: categoryRepository,
      now: now ?? () => analyticsTestNow,
      localUtcOffset: localUtcOffset ?? Duration.zero,
    );
  }

  /// The fake analytics store.
  final FakeAnalyticsRepository analyticsRepository;

  /// The fake transaction store.
  final FakeTransactionRepository transactionRepository;

  /// The fake account store.
  final FakeAccountRepository accountRepository;

  /// The fake category store.
  final FakeCategoryRepository categoryRepository;

  /// The fake budget store.
  final FakeBudgetRepository budgetRepository;

  /// The service under test, backed by the fakes.
  late final AnalyticsService service;
}

/// Builds a named category for analytics tests.
Category testAnalyticsCategory({required String id, required String name}) {
  return Category(id: id, name: name, iconKey: 'category', colorHex: '#22C55E');
}

/// Builds a cash account for analytics tests.
Account testAccount({
  String id = 'account-1',
  String name = 'Cash',
  int balanceMinorUnits = 100000,
}) {
  return Account(
    id: id,
    name: name,
    type: AccountType.cash,
    currency: 'EGP',
    balanceMinorUnits: balanceMinorUnits,
  );
}

/// Builds an expense transaction for analytics tests.
Transaction testTransaction({
  required String id,
  required DateTime timestamp,
  int amountMinorUnits = 1000,
  TransactionType type = TransactionType.expense,
  String accountId = 'account-1',
  String? categoryId,
  TransactionSource source = TransactionSource.manual,
  String? payee,
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    amountMinorUnits: amountMinorUnits,
    timestamp: timestamp,
    type: type,
    source: source,
    categoryId: categoryId,
    payee: payee,
  );
}
