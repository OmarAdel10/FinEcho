import 'package:finecho/features/budget/view/widgets/add_budget_sheet.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_budget_repositories.dart';

Widget _wrap(BudgetCubit cubit, AddBudgetSheet child) {
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
  testWidgets('creates a budget and closes after success', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
      newId: () => 'budget-new',
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const AddBudgetSheet()));
    await tester.enterText(find.byType(TextFormField).first, '12.50');
    await _selectCategory(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(harness.budgetRepository.budgets['budget-new'], isNotNull);
  });

  testWidgets('keeps the sheet open for an invalid amount', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const AddBudgetSheet()));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    expect(find.byType(AddBudgetSheet), findsOneWidget);
    expect(harness.budgetRepository.budgets, isEmpty);
  });

  testWidgets('requires a category before submit', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const AddBudgetSheet()));
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a valid category.'), findsOneWidget);
    expect(harness.budgetRepository.budgets, isEmpty);
  });

  testWidgets('pre-fills and updates an existing budget', (tester) async {
    final original = testBudget();
    final harness = BudgetTestHarness(
      initialBudgets: {original.id: original},
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, AddBudgetSheet(initial: original)));
    expect(find.text('100.00'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '25');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      harness.budgetRepository.budgets[original.id]?.allocatedAmountMinorUnits,
      2500,
    );
    expect(harness.budgetRepository.updatedIds, <String>[original.id]);
  });

  testWidgets('explains that categories are required', (tester) async {
    final harness = BudgetTestHarness();
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const AddBudgetSheet()));

    expect(find.text('No categories yet'), findsOneWidget);
    expect(
      find.text('Add a category before creating a budget.'),
      findsOneWidget,
    );
  });
}
