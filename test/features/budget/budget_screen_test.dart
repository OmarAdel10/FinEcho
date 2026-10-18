import 'package:finecho/features/budget/view/screens/budget_screen.dart';
import 'package:finecho/features/budget/view/widgets/budget_tile.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_budget_repositories.dart';

Widget _wrap(BudgetCubit cubit, Widget child) {
  return MaterialApp(
    home: BlocProvider<BudgetCubit>.value(value: cubit, child: child),
  );
}

Future<BudgetCubit> _loadedCubit(BudgetTestHarness harness) async {
  final cubit = BudgetCubit(harness.service);
  addTearDown(cubit.close);
  await cubit.load();
  return cubit;
}

Future<void> _selectCategory(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Food').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the blocked state before categories exist', (
    tester,
  ) async {
    final harness = BudgetTestHarness();
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const BudgetScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No budgets yet'), findsOneWidget);
    expect(
      find.text('Tap Add budget to set a spending limit for a category.'),
      findsOneWidget,
    );
  });

  testWidgets('shows loading while budgets load', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = BudgetCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit, const BudgetScreen()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders budget rows with category names', (tester) async {
    final harness = BudgetTestHarness(
      initialBudgets: {'budget-1': testBudget()},
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const BudgetScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetTile), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Monthly • 2026-10-01'), findsOneWidget);
  });

  testWidgets('refreshes an already-ready cubit on entry', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);
    await harness.budgetRepository.create(testBudget(id: 'budget-late'));

    await tester.pumpWidget(_wrap(cubit, const BudgetScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetTile), findsOneWidget);
    expect(find.text('100.00'), findsOneWidget);
  });

  testWidgets('creates a budget from the add sheet', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
      newId: () => 'budget-new',
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const BudgetScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add budget'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '12.50');
    await _selectCategory(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetTile), findsOneWidget);
    expect(find.text('12.50'), findsOneWidget);
    expect(harness.budgetRepository.budgets['budget-new'], isNotNull);
  });

  testWidgets('keeps the sheet open for an invalid amount', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const BudgetScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    expect(harness.budgetRepository.budgets, isEmpty);
  });

  testWidgets('edits a budget from its row', (tester) async {
    final harness = BudgetTestHarness(
      initialBudgets: {'budget-1': testBudget()},
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const BudgetScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BudgetTile));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '25');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('25.00'), findsOneWidget);
    expect(
      harness.budgetRepository.budgets['budget-1']?.allocatedAmountMinorUnits,
      2500,
    );
    expect(harness.budgetRepository.updatedIds, <String>['budget-1']);
  });

  testWidgets('deletes a budget after confirmation', (tester) async {
    final harness = BudgetTestHarness(
      initialBudgets: {'budget-1': testBudget()},
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const BudgetScreen()));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetTile), findsNothing);
    expect(harness.budgetRepository.deletedIds, <String>['budget-1']);
  });

  testWidgets('keeps a budget when deletion fails', (tester) async {
    final harness = BudgetTestHarness(
      initialBudgets: {'budget-1': testBudget()},
      initialCategories: {'category-1': testCategory()},
    );
    harness.budgetRepository.deleteError = Exception('delete failed');
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const BudgetScreen()));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(BudgetTile), findsOneWidget);
    expect(
      find.text('Could not delete the budget. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('retries after a load failure', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
    );
    harness.budgetRepository.listError = Exception('load failed');
    final cubit = BudgetCubit(harness.service);
    addTearDown(cubit.close);

    await tester.pumpWidget(_wrap(cubit, const BudgetScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);

    harness.budgetRepository.listError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsNothing);
    expect(find.byType(BudgetTile), findsNothing);
  });
}
