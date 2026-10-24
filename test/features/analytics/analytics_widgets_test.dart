import 'dart:math' as math;

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

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = math.max(foregroundLuminance, backgroundLuminance);
  final darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
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
            hasPreviousPeriod: true,
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
            hasPreviousPeriod: true,
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
            hasPreviousPeriod: true,
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
            hasPreviousPeriod: false,
          ),
        ),
      );

      expect(find.text('No previous period to compare'), findsOneWidget);
    });

    testWidgets('explains a previous period without spending', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AnalyticsSummaryCard(
            totalIncomeMinorUnits: 100000,
            totalExpenseMinorUnits: 100000,
            netAmountMinorUnits: 0,
            expenseChangeRatio: null,
            hasPreviousPeriod: true,
          ),
        ),
      );

      expect(
        find.text('No spending in the same days of the previous period'),
        findsOneWidget,
      );
      expect(find.text('No previous period to compare'), findsNothing);
    });

    testWidgets('formats cents and negative cents', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AnalyticsSummaryCard(
            totalIncomeMinorUnits: 12345,
            totalExpenseMinorUnits: 5,
            netAmountMinorUnits: -12345,
            expenseChangeRatio: null,
            hasPreviousPeriod: true,
          ),
        ),
      );

      expect(find.text('123.45'), findsOneWidget);
      expect(find.text('0.05'), findsOneWidget);
      expect(find.text('-123.45'), findsOneWidget);
    });

    testWidgets('drops the fraction for zero-decimal currencies', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AnalyticsSummaryCard(
            totalIncomeMinorUnits: 1234,
            totalExpenseMinorUnits: 2,
            netAmountMinorUnits: 1232,
            expenseChangeRatio: null,
            hasPreviousPeriod: true,
            currency: 'JPY',
          ),
        ),
      );

      expect(find.text('1234'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1232'), findsOneWidget);
      expect(find.text('1234.00'), findsNothing);
    });

    testWidgets('keeps three fraction digits for three-decimal currencies', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AnalyticsSummaryCard(
            totalIncomeMinorUnits: 123456,
            totalExpenseMinorUnits: 500,
            netAmountMinorUnits: 122956,
            expenseChangeRatio: null,
            hasPreviousPeriod: true,
            currency: 'BHD',
          ),
        ),
      );

      expect(find.text('123.456'), findsOneWidget);
      expect(find.text('0.500'), findsOneWidget);
      expect(find.text('122.956'), findsOneWidget);
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
      final semantics = tester.ensureSemantics();
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
      final ringSemantics = tester.widget<Semantics>(
        find
            .ancestor(of: _ringPainter(), matching: find.byType(Semantics))
            .first,
      );
      expect(
        ringSemantics.properties.label,
        'Spending ring by category, Food 75.00, Transport 25.00',
      );
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('75.00'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('25.00'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      semantics.dispose();
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

    testWidgets('labels a category without a name as uncategorized', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryBreakdownCard(
            categoryTotals: [
              CategoryTotal(
                categoryId: null,
                name: null,
                expenseMinorUnits: 1000,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Uncategorized'), findsOneWidget);
      expect(find.text('10.00'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('formats cents in the legend', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryBreakdownCard(
            categoryTotals: [
              CategoryTotal(
                categoryId: 'category-1',
                name: 'Food',
                expenseMinorUnits: 5,
              ),
            ],
          ),
        ),
      );

      expect(find.text('0.05'), findsOneWidget);
    });

    testWidgets('repaints when ring slices change', (tester) async {
      Widget card(List<CategoryTotal> totals) {
        return _wrap(CategoryBreakdownCard(categoryTotals: totals));
      }

      await tester.pumpWidget(
        card(const [
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
        ]),
      );
      final before = tester.widget<CustomPaint>(_ringPainter()).painter!;
      expect(before.shouldRepaint(before), isFalse);

      await tester.pumpWidget(
        card(const [
          CategoryTotal(
            categoryId: 'category-1',
            name: 'Food',
            expenseMinorUnits: 5000,
          ),
          CategoryTotal(
            categoryId: 'category-2',
            name: 'Transport',
            expenseMinorUnits: 5000,
          ),
        ]),
      );
      final after = tester.widget<CustomPaint>(_ringPainter()).painter!;
      expect(after.shouldRepaint(before), isTrue);
    });
    testWidgets('rounds legend percentages so they sum to one hundred', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryBreakdownCard(
            categoryTotals: [
              CategoryTotal(
                categoryId: 'category-1',
                name: 'Food',
                expenseMinorUnits: 1,
              ),
              CategoryTotal(
                categoryId: 'category-2',
                name: 'Transport',
                expenseMinorUnits: 1,
              ),
              CategoryTotal(
                categoryId: 'category-3',
                name: 'Bills',
                expenseMinorUnits: 1,
              ),
            ],
          ),
        ),
      );

      final percents = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(CategoryBreakdownCard),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .whereType<String>()
          .where((text) => text.endsWith('%'))
          .map((text) => int.parse(text.substring(0, text.length - 1)))
          .toList();

      expect(percents, [34, 33, 33]);
      expect(percents.fold<int>(0, (sum, value) => sum + value), 100);
    });

    testWidgets('cycles the slice palette after six categories', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CategoryBreakdownCard(
            categoryTotals: [
              for (var index = 0; index < 8; index++)
                CategoryTotal(
                  categoryId: 'category-$index',
                  name: 'Category $index',
                  expenseMinorUnits: 1000,
                ),
            ],
          ),
        ),
      );

      final colors = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(CategoryBreakdownCard),
              matching: find.byType(Container),
            ),
          )
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .where((decoration) => decoration.shape == BoxShape.circle)
          .map((decoration) => decoration.color)
          .toList();

      expect(colors, hasLength(8));
      expect(colors.take(6).toSet(), hasLength(6));
      expect(colors[6], colors[0]);
      expect(colors[7], colors[1]);
    });

    testWidgets('uses income amounts for income rings and percentages', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryBreakdownCard(
            metric: CategoryBreakdownMetric.income,
            categoryTotals: [
              CategoryTotal(
                categoryId: 'category-1',
                name: 'Salary',
                expenseMinorUnits: 0,
                incomeMinorUnits: 5000,
              ),
              CategoryTotal(
                categoryId: 'category-2',
                name: 'Freelance',
                expenseMinorUnits: 0,
                incomeMinorUnits: 3000,
              ),
              CategoryTotal(
                categoryId: 'category-3',
                name: 'Bonus',
                expenseMinorUnits: 0,
                incomeMinorUnits: 2000,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Income by category'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
    });

    testWidgets('splits remainders without dropping categories', (
      tester,
    ) async {
      Future<List<int>> render(List<int> amounts) async {
        await tester.pumpWidget(
          _wrap(
            CategoryBreakdownCard(
              categoryTotals: [
                for (var index = 0; index < amounts.length; index++)
                  CategoryTotal(
                    categoryId: 'category-$index',
                    name: 'Category $index',
                    expenseMinorUnits: amounts[index],
                  ),
              ],
            ),
          ),
        );
        return tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(CategoryBreakdownCard),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data)
            .whereType<String>()
            .where((text) => text.endsWith('%'))
            .map((text) => int.parse(text.substring(0, text.length - 1)))
            .toList();
      }

      expect(await render([0, 1, 1, 1]), [0, 34, 33, 33]);
      expect(await render([1, 1, 1, 1, 1, 1]), [17, 17, 17, 17, 16, 16]);
      expect(await render([100, 0]), [100, 0]);
      expect(await render([0, 0]), [0, 0]);
    });

    testWidgets('paints slices with the legend colors', (tester) async {
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

      final painter = tester.widget<CustomPaint>(_ringPainter()).painter!;
      final painterColors = (painter as dynamic).colors as List<Color>;
      final legendColors = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(CategoryBreakdownCard),
              matching: find.byType(Container),
            ),
          )
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .where((decoration) => decoration.shape == BoxShape.circle)
          .map((decoration) => decoration.color)
          .toList();

      expect(painterColors.take(legendColors.length), legendColors);
    });
  });

  test('keeps slice colors legible in both themes', () {
    for (final theme in [FinEchoTheme.light(), FinEchoTheme.dark()]) {
      final palette = slicePaletteFor(theme.brightness);
      final surface = theme.colorScheme.surfaceContainerHighest;

      expect(palette, hasLength(6));
      expect(palette.toSet(), hasLength(palette.length));
      for (final color in palette) {
        expect(
          _contrastRatio(color, surface),
          greaterThanOrEqualTo(3),
          reason: 'Slice color $color must contrast with $surface',
        );
      }
    }
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
      final semantics = tester.ensureSemantics();
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
      final rowSemantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byType(LinearProgressIndicator),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(rowSemantics.properties.label, 'Food budget');
      expect(rowSemantics.properties.value, '50.00 of 100.00 spent');
      semantics.dispose();
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

      final context = tester.element(find.byType(LinearProgressIndicator));
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 1.0);
      expect(indicator.color, Theme.of(context).colorScheme.error);
      expect(find.text('150.00 / 100.00'), findsOneWidget);
      expect(find.text('Over budget'), findsOneWidget);
    });

    testWidgets('formats cents in spent and allocated amounts', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BudgetProgressCard(
            budgetProgress: [
              BudgetProgress(
                budgetId: 'budget-1',
                categoryId: 'category-1',
                categoryName: 'Food',
                allocatedAmountMinorUnits: 12345,
                spentAmountMinorUnits: 5,
                level: BudgetProgressLevel.normal,
              ),
            ],
          ),
        ),
      );

      expect(find.text('0.05 / 123.45'), findsOneWidget);
    });
  });

  group('InsightsCard', () {
    testWidgets('shows the empty section messages', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const InsightsCard(
            forecast: MonthlyForecast(
              elapsedDays: 15,
              daysInMonth: 31,
              expenseSoFarMinorUnits: 0,
              projectedExpenseMinorUnits: 0,
            ),
            recurringCharges: [],
            unusualSpikes: [],
          ),
        ),
      );

      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Current calendar month'), findsOneWidget);
      expect(find.text('Projected month-end spending'), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('Based on 15 of 31 days so far'), findsOneWidget);
      expect(find.text('Recurring charges'), findsOneWidget);
      expect(find.text('No recurring charges yet.'), findsOneWidget);
      expect(find.text('Unusual spending'), findsOneWidget);
      expect(find.text('No unusual spending.'), findsOneWidget);
    });

    testWidgets('formats cents in the forecast', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const InsightsCard(
            forecast: MonthlyForecast(
              elapsedDays: 15,
              daysInMonth: 31,
              expenseSoFarMinorUnits: 5000,
              projectedExpenseMinorUnits: 12345,
            ),
            recurringCharges: [],
            unusualSpikes: [],
          ),
        ),
      );

      expect(find.text('123.45'), findsOneWidget);
    });
  });
}
