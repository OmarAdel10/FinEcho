import 'package:finecho/app/theme/fin_echo_theme.dart';
import 'package:finecho/core/models/category_total.dart';
import 'package:finecho/features/analytics/view/widgets/analytics_summary_card.dart';
import 'package:finecho/features/analytics/view/widgets/budget_progress_card.dart';
import 'package:finecho/features/analytics/view/widgets/category_breakdown_card.dart';
import 'package:finecho/features/analytics/view/widgets/insights_card.dart';
import 'package:finecho/features/analytics/view_model/models/budget_progress.dart';
import 'package:finecho/features/analytics/view_model/models/monthly_forecast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

Finder _ringPainter() {
  return find.descendant(
    of: find.byType(CategoryBreakdownCard),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter?.runtimeType.toString() == '_CategoryRingPainter',
    ),
  );
}

void main() {
  group('AnalyticsSummaryCard', () {
    testWidgets('shows income, expenses, net, and an upward trend', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AnalyticsSummaryCard(
            totalIncomeMinorUnits: 500000,
            totalExpenseMinorUnits: 124000,
            netAmountMinorUnits: 376000,
            expenseChangeRatio: 0.24,
          ),
        ),
      );

      expect(find.text('Income'), findsOneWidget);
      expect(find.text('5000.00'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('1240.00'), findsOneWidget);
      expect(find.text('Net'), findsOneWidget);
      expect(find.text('3760.00'), findsOneWidget);
      expect(find.text('Spending up 24% vs previous period'), findsOneWidget);
    });

    testWidgets('shows a downward trend and a negative net', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AnalyticsSummaryCard(
            totalIncomeMinorUnits: 100000,
            totalExpenseMinorUnits: 112000,
            netAmountMinorUnits: -12000,
            expenseChangeRatio: -0.12,
          ),
        ),
      );

      expect(find.text('Spending down 12% vs previous period'), findsOneWidget);
      expect(find.text('-120.00'), findsOneWidget);
    });

    testWidgets('shows a flat trend at a zero change', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AnalyticsSummaryCard(
            totalIncomeMinorUnits: 100000,
            totalExpenseMinorUnits: 100000,
            netAmountMinorUnits: 0,
            expenseChangeRatio: 0,
          ),
        ),
      );

      expect(find.text('Spending flat 0% vs previous period'), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);
    });

    testWidgets('explains a missing previous period', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AnalyticsSummaryCard(
            totalIncomeMinorUnits: 100000,
            totalExpenseMinorUnits: 100000,
            netAmountMinorUnits: 0,
            expenseChangeRatio: null,
          ),
        ),
      );

      expect(find.text('No previous period to compare'), findsOneWidget);
    });
  });

  group('CategoryBreakdownCard', () {
    testWidgets('shows the empty message without spending', (tester) async {
      await tester.pumpWidget(
        _wrap(const CategoryBreakdownCard(categoryTotals: [])),
      );

      expect(find.text('Spending by category'), findsOneWidget);
      expect(find.text('No spending in this period.'), findsOneWidget);
      expect(_ringPainter(), findsNothing);
    });

    testWidgets('renders a ring and legend percentages', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryBreakdownCard(
            categoryTotals: [
              CategoryTotal(
                categoryId: 'category-1',
                name: 'Food',
                expenseMinorUnits: 7500,
              ),
              CategoryTotal(
                categoryId: 'category-2',
                name: 'Transport',
                expenseMinorUnits: 2500,
              ),
            ],
          ),
        ),
      );

      expect(_ringPainter(), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('75.00'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('25.00'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('guards percentages when the total is zero', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryBreakdownCard(
            categoryTotals: [
              CategoryTotal(
                categoryId: 'category-1',
                name: 'Food',
                expenseMinorUnits: 0,
              ),
            ],
          ),
        ),
      );

      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });
  });

  group('BudgetProgressCard', () {
    testWidgets('renders nothing without budgets', (tester) async {
      await tester.pumpWidget(
        _wrap(const BudgetProgressCard(budgetProgress: [])),
      );

      expect(find.text('Budgets'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('keeps a normal budget on the theme primary color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BudgetProgressCard(
            budgetProgress: [
              BudgetProgress(
                budgetId: 'budget-1',
                categoryId: 'category-1',
                categoryName: 'Food',
                allocatedAmountMinorUnits: 10000,
                spentAmountMinorUnits: 5000,
                level: BudgetProgressLevel.normal,
              ),
            ],
          ),
        ),
      );

      final context = tester.element(find.byType(LinearProgressIndicator));
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0.5);
      expect(indicator.color, Theme.of(context).colorScheme.primary);
      expect(find.text('50.00 / 100.00'), findsOneWidget);
    });

    testWidgets('clamps an exceeded budget and uses the coral accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BudgetProgressCard(
            budgetProgress: [
              BudgetProgress(
                budgetId: 'budget-1',
                categoryId: 'category-1',
                categoryName: 'Food',
                allocatedAmountMinorUnits: 10000,
                spentAmountMinorUnits: 15000,
                level: BudgetProgressLevel.exceeded,
              ),
            ],
          ),
        ),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 1.0);
      expect(indicator.color, FinEchoColors.coral);
      expect(find.text('150.00 / 100.00'), findsOneWidget);
    });
  });

  group('InsightsCard', () {
    testWidgets('shows the empty section messages', (tester) async {
      await tester.pumpWidget(
        _wrap(
          InsightsCard(
            forecast: MonthlyForecast(
              monthStartUtc: DateTime.utc(2026, 10),
              monthEndUtc: DateTime.utc(2026, 11),
              elapsedDays: 15,
              daysInMonth: 31,
              expenseSoFarMinorUnits: 0,
              projectedExpenseMinorUnits: 0,
            ),
            recurringCharges: const [],
            unusualSpikes: const [],
          ),
        ),
      );

      expect(find.text('Projected month-end spending'), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('Based on 15 of 31 days so far'), findsOneWidget);
      expect(find.text('Recurring charges'), findsOneWidget);
      expect(find.text('No recurring charges yet.'), findsOneWidget);
      expect(find.text('Unusual spending'), findsOneWidget);
      expect(find.text('No unusual spending.'), findsOneWidget);
    });
  });
}
