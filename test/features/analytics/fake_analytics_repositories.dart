import 'dart:async';

import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
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
  new({AnalyticsSummary? summary, this.onSummary, this.error})
    : summary = summary ?? _emptySummary;

  /// The summary returned when [onSummary] is not set.
  final AnalyticsSummary summary;

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
  }) async {
    if (!startUtc.isBefore(endUtc)) {
      throw ArgumentError.value(endUtc, 'endUtc', 'must be after startUtc');
    }
    requestedRanges.add((startUtc, endUtc));
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
    service = AnalyticsService(
      analytics: analyticsRepository,
      transactions: transactionRepository,
      accounts: accountRepository,
      budgets: budgetRepository,
      categories: categoryRepository,
      now: now ?? () => analyticsTestNow,
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
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    amountMinorUnits: amountMinorUnits,
    timestamp: timestamp,
    type: type,
    source: source,
    categoryId: categoryId,
  );
}
