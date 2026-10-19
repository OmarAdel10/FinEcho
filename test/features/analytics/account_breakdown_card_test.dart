import 'package:finecho/features/analytics/view/widgets/account_breakdown_card.dart';
import 'package:finecho/features/analytics/view_model/models/account_total.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    List<AccountTotal> accountTotals, {
    AccountBreakdownMetric metric = AccountBreakdownMetric.expense,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountBreakdownCard(
            accountTotals: accountTotals,
            metric: metric,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the empty message without account activity', (
    tester,
  ) async {
    await pumpCard(tester, const []);

    expect(find.text('By account'), findsOneWidget);
    expect(find.text('No account activity in this period.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('renders expense shares and amounts per account', (tester) async {
    await pumpCard(tester, const [
      AccountTotal(
        accountId: 'account-1',
        name: 'Cash',
        incomeMinorUnits: 20000,
        expenseMinorUnits: 10000,
      ),
      AccountTotal(
        accountId: 'account-2',
        name: 'Bank',
        incomeMinorUnits: 0,
        expenseMinorUnits: 4000,
      ),
    ]);

    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('100.00'), findsOneWidget);
    expect(find.text('40.00'), findsOneWidget);

    final values = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .map((indicator) => indicator.value)
        .toList();
    expect(values, [1.0, 0.4]);
  });

  testWidgets('keeps zero progress when no account spent', (tester) async {
    await pumpCard(tester, const [
      AccountTotal(
        accountId: 'account-1',
        name: 'Cash',
        incomeMinorUnits: 5000,
        expenseMinorUnits: 0,
      ),
    ]);

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 0.0);
    expect(find.text('0.00'), findsOneWidget);
  });

  testWidgets('shares income when the income metric is selected', (
    tester,
  ) async {
    await pumpCard(tester, const [
      AccountTotal(
        accountId: 'account-1',
        name: 'Cash',
        incomeMinorUnits: 20000,
        expenseMinorUnits: 10000,
      ),
      AccountTotal(
        accountId: 'account-2',
        name: 'Bank',
        incomeMinorUnits: 0,
        expenseMinorUnits: 4000,
      ),
    ], metric: AccountBreakdownMetric.income);

    expect(find.text('200.00'), findsOneWidget);
    expect(find.text('0.00'), findsOneWidget);

    final values = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .map((indicator) => indicator.value)
        .toList();
    expect(values, [1.0, 0.0]);
  });
}
