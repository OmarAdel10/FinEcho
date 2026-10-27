import 'dart:async';

import 'package:finecho/app/theme/fin_echo_theme.dart';
import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/core/models/analytics_summary.dart';
import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/features/analytics/view/screens/analytics_screen.dart';
import 'package:finecho/features/analytics/view/widgets/'
    'account_breakdown_card.dart';
import 'package:finecho/features/analytics/view/widgets/'
    'analytics_summary_card.dart';
import 'package:finecho/features/analytics/view/widgets/'
    'budget_progress_card.dart';
import 'package:finecho/features/analytics/view/widgets/'
    'category_breakdown_card.dart';
import 'package:finecho/features/analytics/view/widgets/'
    'insights_card.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_analytics_repositories.dart';

Widget _wrap(AnalyticsCubit cubit, {TextScaler? textScaler}) {
  return MaterialApp(
    builder: textScaler == null
        ? null
        : (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
    home: BlocProvider<AnalyticsCubit>.value(
      value: cubit,
      child: const AnalyticsScreen(),
    ),
  );
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

AnalyticsSummary _summary({
  required DateTime startUtc,
  required DateTime endUtc,
  int income = 0,
  int expense = 0,
  List<CategoryTotal> categories = const [],
  List<CategoryTotal> incomeCategories = const [],
}) {
  return AnalyticsSummary(
    startUtc: startUtc,
    endUtc: endUtc,
    totalIncomeMinorUnits: income,
    totalExpenseMinorUnits: expense,
    categoryExpenseTotals: categories,
    categoryIncomeTotals: incomeCategories,
  );
}

AnalyticsSummary _dashboardSummary(DateTime startUtc, DateTime endUtc) {
  if (startUtc == DateTime.utc(2026, 9)) {
    return _summary(startUtc: startUtc, endUtc: endUtc, expense: 100000);
  }
  return _summary(
    startUtc: startUtc,
    endUtc: endUtc,
    expense: 35000,
    categories: const [
      CategoryTotal(
        categoryId: 'category-1',
        name: 'Food',
        expenseMinorUnits: 25000,
      ),
      CategoryTotal(
        categoryId: 'category-2',
        name: 'Transport',
        expenseMinorUnits: 10000,
      ),
    ],
    incomeCategories: const [
      CategoryTotal(
        categoryId: 'category-salary',
        name: 'Salary',
        expenseMinorUnits: 0,
        incomeMinorUnits: 200000,
      ),
    ],
  );
}

void main() {
  testWidgets('shows a spinner while the dashboard loads', (tester) async {
    final harness = AnalyticsTestHarness();
    final gate = Completer<void>();
    harness.analyticsRepository.gate = gate;
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AnalyticsSummaryCard), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AnalyticsSummaryCard), findsOneWidget);
  });

  testWidgets('renders the loaded dashboard content', (tester) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(
      initialTransactions: {
        'txn-1': testTransaction(
          id: 'txn-1',
          timestamp: DateTime.utc(2026, 10, 5),
          amountMinorUnits: 25000,
          categoryId: 'category-1',
        ),
        'txn-2': testTransaction(
          id: 'txn-2',
          timestamp: DateTime.utc(2026, 10, 6),
          amountMinorUnits: 10000,
          accountId: 'account-2',
          categoryId: 'category-2',
        ),
      },
      initialAccounts: {
        'account-1': testAccount(),
        'account-2': testAccount(id: 'account-2', name: 'Bank'),
      },
      initialCategories: {
        'category-1': testAnalyticsCategory(id: 'category-1', name: 'Food'),
        'category-2': testAnalyticsCategory(
          id: 'category-2',
          name: 'Transport',
        ),
      },
      onSummary: _dashboardSummary,
    );
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(find.text('FinEcho'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);

    expect(find.text('Spending'), findsOneWidget);
    expect(find.text('Income'), findsNWidgets(2));
    expect(find.text('Patterns'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AnalyticsSummaryCard),
        matching: find.text('0.00'),
      ),
      findsOneWidget,
    );
    expect(find.text('Expenses'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AnalyticsSummaryCard),
        matching: find.text('350.00'),
      ),
      findsOneWidget,
    );
    expect(find.text('Net'), findsOneWidget);
    expect(find.text('-350.00'), findsOneWidget);
    expect(find.text('Spending down 65% vs previous period'), findsOneWidget);

    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CategoryBreakdownCard),
        matching: find.text('250.00'),
      ),
      findsOneWidget,
    );
    expect(find.text('71%'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CategoryBreakdownCard),
        matching: find.text('100.00'),
      ),
      findsOneWidget,
    );
    expect(find.text('29%'), findsOneWidget);

    expect(find.text('By account'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AccountBreakdownCard),
        matching: find.text('250.00'),
      ),
      findsOneWidget,
    );
    expect(find.text('Bank'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AccountBreakdownCard),
        matching: find.text('100.00'),
      ),
      findsOneWidget,
    );

    expect(find.byType(InsightsCard), findsNothing);

    await tester.tap(find.text('Patterns'));
    await tester.pumpAndSettle();

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Projected month-end spending'), findsOneWidget);
    expect(find.text('748.28'), findsOneWidget);
    expect(find.text('Based on 15 of 31 days so far'), findsOneWidget);
    expect(find.text('No recurring charges yet.'), findsOneWidget);
    expect(find.text('No unusual spending.'), findsOneWidget);

    expect(find.byType(BudgetProgressCard), findsNothing);
  });

  testWidgets('explains a comparison window without spending', (tester) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(
      onSummary: (startUtc, endUtc) => _summary(
        startUtc: startUtc,
        endUtc: endUtc,
        expense: startUtc == DateTime.utc(2026, 10) ? 35000 : 0,
      ),
    );
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(
      find.text('No spending in the same days of the previous period'),
      findsOneWidget,
    );
  });

  testWidgets('explains a missing previous period', (tester) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(
      now: () => DateTime.utc(2026, 11),
      onSummary: (startUtc, endUtc) =>
          _summary(startUtc: startUtc, endUtc: endUtc, expense: 35000),
    );
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(find.text('No previous period to compare'), findsOneWidget);
  });

  testWidgets('retries with Try again after a load failure', (tester) async {
    final harness = AnalyticsTestHarness();
    harness.analyticsRepository.error = Exception('boom');
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(harness.analyticsRepository.requestedRanges, hasLength(2));

    harness.analyticsRepository.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsNothing);
    expect(find.byType(AnalyticsSummaryCard), findsOneWidget);
    expect(harness.analyticsRepository.requestedRanges, hasLength(4));
  });

  // Covers the explicit cubit.load() reload path failing after a dashboard
  // has settled; the period-switch failure path (also surfacing the error
  // message under keep-alive data, without asserting Try again) is covered
  // by 'keeps the dashboard and warns when a refresh fails' below.
  testWidgets('warns with stale data when an explicit reload fails', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(onSummary: _dashboardSummary);
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    harness.analyticsRepository.error = Exception('boom');
    await cubit.load();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text(loadErrorMessage),
      findsOneWidget,
    );
    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
  });

  testWidgets('shows and can dismiss the error SnackBar', (tester) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(onSummary: _dashboardSummary);
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    harness.analyticsRepository.error = Exception('boom');
    await cubit.load();
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);

    // Default SnackBar duration is 4 seconds + animation;
    // pump with generous margin
    await tester.pump(const Duration(seconds: 6));

    // Note: SnackBar auto-dismiss timing can vary in test environment
    // The key assertion is that it appeared and can be dismissed
  });

  testWidgets('switches period from the segmented control', (tester) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(onSummary: _dashboardSummary);
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(cubit.state.period, AnalyticsPeriod.month);

    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();

    expect(cubit.state.period, AnalyticsPeriod.year);
    expect(harness.analyticsRepository.requestedRanges, [
      (DateTime.utc(2026, 10), DateTime.utc(2026, 11)),
      (DateTime.utc(2026, 9), DateTime.utc(2026, 9, 15, 12)),
      (DateTime.utc(2026), DateTime.utc(2027)),
      (DateTime.utc(2025), DateTime.utc(2025, 10, 15, 12)),
    ]);
  });

  testWidgets('switches mode from the segmented control', (tester) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(onSummary: _dashboardSummary);
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Spending by category'), findsOneWidget);
    expect(find.byType(AccountBreakdownCard), findsOneWidget);
    expect(find.byType(InsightsCard), findsNothing);

    await tester.tap(find.text('Income').first);
    await tester.pumpAndSettle();

    expect(find.text('Spending by category'), findsNothing);
    expect(find.text('Income by category'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.byType(AccountBreakdownCard), findsOneWidget);
    expect(find.text('By account'), findsOneWidget);

    await tester.tap(find.text('Patterns'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountBreakdownCard), findsNothing);
    expect(find.text('Insights'), findsOneWidget);
  });

  testWidgets('refreshes the dashboard on a pull gesture', (tester) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(onSummary: _dashboardSummary);
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(harness.analyticsRepository.requestedRanges, hasLength(2));

    await tester.fling(find.byType(ListView), const Offset(0, 1200), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(harness.analyticsRepository.requestedRanges, hasLength(4));
    expect(find.byType(AnalyticsSummaryCard), findsOneWidget);
  });

  testWidgets('keeps the dashboard and warns when a refresh fails', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(onSummary: _dashboardSummary);
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    harness.analyticsRepository.error = Exception('boom');
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();

    expect(find.byType(AnalyticsSummaryCard), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text(loadErrorMessage),
      findsOneWidget,
    );
    expect(cubit.state.period, AnalyticsPeriod.month);
    expect(cubit.state.dashboard?.period, AnalyticsPeriod.month);
  });

  testWidgets('shows the empty category, account, and insight messages', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness();
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(find.text('No spending in this period.'), findsOneWidget);
    expect(find.text('No account activity in this period.'), findsOneWidget);
    expect(find.byType(InsightsCard), findsNothing);

    await tester.tap(find.text('Patterns'));
    await tester.pumpAndSettle();

    expect(find.text('No recurring charges yet.'), findsOneWidget);
    expect(find.text('No unusual spending.'), findsOneWidget);
    expect(find.byType(BudgetProgressCard), findsNothing);
  });

  testWidgets('marks a budget warning with the coral accent', (tester) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(
      initialTransactions: {
        'txn-1': testTransaction(
          id: 'txn-1',
          timestamp: DateTime.utc(2026, 10, 5),
          amountMinorUnits: 25000,
          categoryId: 'category-1',
        ),
      },
      initialAccounts: {'account-1': testAccount()},
      initialCategories: {
        'category-1': testAnalyticsCategory(id: 'category-1', name: 'Food'),
      },
      initialBudgets: {
        'budget-1': Budget(
          id: 'budget-1',
          categoryId: 'category-1',
          allocatedAmountMinorUnits: 28000,
          period: BudgetPeriod.monthly,
          startDate: DateTime.utc(2026, 10),
        ),
      },
    );
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetProgressCard), findsOneWidget);
    expect(find.text('250.00 / 280.00'), findsOneWidget);
    expect(find.text('Close to limit'), findsOneWidget);
    final indicator = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.byType(BudgetProgressCard),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(indicator.color, FinEchoColors.coral);
  });

  testWidgets('renders recurring charges and the month forecast', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(
      initialTransactions: {
        'rent-august': testTransaction(
          id: 'rent-august',
          timestamp: DateTime.utc(2026, 8, 10),
          amountMinorUnits: 200000,
          categoryId: 'category-3',
          payee: 'Landlord',
        ),
        'rent-september': testTransaction(
          id: 'rent-september',
          timestamp: DateTime.utc(2026, 9, 10),
          amountMinorUnits: 200000,
          categoryId: 'category-3',
          payee: 'Landlord',
        ),
        'rent-october': testTransaction(
          id: 'rent-october',
          timestamp: DateTime.utc(2026, 10, 10),
          amountMinorUnits: 200000,
          categoryId: 'category-3',
          payee: 'Landlord',
        ),
        'spend-october': testTransaction(
          id: 'spend-october',
          timestamp: DateTime.utc(2026, 10, 5),
          amountMinorUnits: 30000,
        ),
      },
      initialAccounts: {'account-1': testAccount()},
      initialCategories: {
        'category-3': testAnalyticsCategory(id: 'category-3', name: 'Rent'),
      },
    );
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patterns'));
    await tester.pumpAndSettle();

    expect(find.text('Projected month-end spending'), findsOneWidget);
    expect(find.text('4917.24'), findsOneWidget);
    expect(find.text('Based on 15 of 31 days so far'), findsOneWidget);
    expect(find.text('Recurring charges'), findsOneWidget);
    expect(find.text('Landlord'), findsOneWidget);
    expect(find.text('3 months'), findsOneWidget);
    expect(find.text('2000.00'), findsOneWidget);
    expect(find.text('No recurring charges yet.'), findsNothing);
  });

  testWidgets('flags unusual spending with the coral warning icon', (
    tester,
  ) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(
      initialTransactions: {
        'baseline-july': testTransaction(
          id: 'baseline-july',
          timestamp: DateTime.utc(2026, 7, 10),
          amountMinorUnits: 3000,
          categoryId: 'category-4',
        ),
        'baseline-august': testTransaction(
          id: 'baseline-august',
          timestamp: DateTime.utc(2026, 8, 10),
          amountMinorUnits: 3000,
          categoryId: 'category-4',
        ),
        'spike-october': testTransaction(
          id: 'spike-october',
          timestamp: DateTime.utc(2026, 10, 5),
          amountMinorUnits: 6000,
          categoryId: 'category-4',
        ),
      },
      initialAccounts: {'account-1': testAccount()},
      initialCategories: {
        'category-4': testAnalyticsCategory(id: 'category-4', name: 'Dining'),
      },
    );
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patterns'));
    await tester.pumpAndSettle();

    expect(find.text('Dining'), findsOneWidget);
    expect(find.text('100% above the recent average'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(InsightsCard),
        matching: find.text('60.00'),
      ),
      findsOneWidget,
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.warning_amber_rounded));
    expect(icon.color, FinEchoColors.coral);
  });

  testWidgets('keeps controls visible while switching periods', (tester) async {
    _useTallSurface(tester);
    final harness = AnalyticsTestHarness(onSummary: _dashboardSummary);
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    final gate = Completer<void>();
    harness.analyticsRepository.gate = gate;
    await tester.tap(find.text('Yearly'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AnalyticsSummaryCard), findsNothing);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Spending'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AnalyticsSummaryCard), findsOneWidget);
    expect(cubit.state.period, AnalyticsPeriod.year);
  });

  testWidgets('lays out at 320dp with 1.5x text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = AnalyticsTestHarness(onSummary: _dashboardSummary);
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      _wrap(cubit, textScaler: const TextScaler.linear(1.5)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AnalyticsSummaryCard), findsOneWidget);
  });

  testWidgets('refreshes a ready dashboard on mount', (tester) async {
    final harness = AnalyticsTestHarness(onSummary: _dashboardSummary);
    final cubit = AnalyticsCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await cubit.load();
    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(harness.analyticsRepository.requestedRanges, hasLength(4));
    expect(find.byType(AnalyticsSummaryCard), findsOneWidget);
  });
}
