import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/features/transactions/view/widgets/period_totals_card.dart';
import 'package:finecho/features/transactions/view_model/models/period_totals.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PeriodTotals _totals({
  int incomeMinorUnits = 50000,
  int expenseMinorUnits = 1250,
}) {
  return PeriodTotals(
    startUtc: DateTime.utc(2026, 10),
    endUtc: DateTime.utc(2026, 11),
    incomeMinorUnits: incomeMinorUnits,
    expenseMinorUnits: expenseMinorUnits,
  );
}

Widget _wrapCard(PeriodTotalsCard card) {
  return MaterialApp(home: Scaffold(body: card));
}

void main() {
  testWidgets('renders the income, expenses, and net metrics', (tester) async {
    await tester.pumpWidget(
      _wrapCard(
        PeriodTotalsCard(
          totals: _totals(),
          selectedPeriod: AnalyticsPeriod.month,
          onPeriodSelected: (_) {},
          localUtcOffset: Duration.zero,
        ),
      ),
    );

    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);
    expect(find.text('500.00'), findsOneWidget);
    expect(find.text('12.50'), findsOneWidget);
    expect(find.text('487.50'), findsOneWidget);
  });

  testWidgets('formats a negative net with a leading sign', (tester) async {
    await tester.pumpWidget(
      _wrapCard(
        PeriodTotalsCard(
          totals: _totals(incomeMinorUnits: 1250, expenseMinorUnits: 50000),
          selectedPeriod: AnalyticsPeriod.month,
          onPeriodSelected: (_) {},
          localUtcOffset: Duration.zero,
        ),
      ),
    );

    expect(find.text('-487.50'), findsOneWidget);
  });

  testWidgets('captions the period boundaries in local time', (tester) async {
    await tester.pumpWidget(
      _wrapCard(
        PeriodTotalsCard(
          totals: _totals(),
          selectedPeriod: AnalyticsPeriod.month,
          onPeriodSelected: (_) {},
          localUtcOffset: Duration.zero,
        ),
      ),
    );

    expect(find.text('Oct 1, 2026 – Oct 31, 2026'), findsOneWidget);
  });

  testWidgets('reports the selected period through the toggle', (tester) async {
    var selected = AnalyticsPeriod.month;
    await tester.pumpWidget(
      _wrapCard(
        PeriodTotalsCard(
          totals: _totals(),
          selectedPeriod: selected,
          onPeriodSelected: (period) {
            selected = period;
          },
          localUtcOffset: Duration.zero,
        ),
      ),
    );

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(selected, AnalyticsPeriod.week);
  });
}
