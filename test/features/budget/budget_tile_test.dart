import 'package:finecho/core/models/budget.dart';
import 'package:finecho/features/budget/view/widgets/budget_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_budget_repositories.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('renders a categorized budget row', (tester) async {
    final budget = testBudget(
      allocatedAmountMinorUnits: 1250,
      period: BudgetPeriod.weekly,
    );

    await tester.pumpWidget(
      _wrap(BudgetTile(budget: budget, categoryName: 'Food')),
    );

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Weekly • 2026-10-01'), findsOneWidget);
    expect(find.text('12.50'), findsOneWidget);
  });

  testWidgets('falls back when the category is missing', (tester) async {
    await tester.pumpWidget(_wrap(BudgetTile(budget: testBudget())));

    expect(find.text('Uncategorized'), findsOneWidget);
    expect(find.text('Monthly • 2026-10-01'), findsOneWidget);
    expect(find.text('100.00'), findsOneWidget);
  });
}
