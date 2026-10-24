import 'dart:async';

import 'package:finecho/features/budget/view/widgets/add_budget_sheet.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_budget_repositories.dart';

Widget _wrap(BudgetCubit cubit, AddBudgetSheet child) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<BudgetCubit>.value(value: cubit, child: child),
    ),
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

Future<void> _selectWarningThreshold(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<int?>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
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

  testWidgets('rejects an amount that is too large', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const AddBudgetSheet()));
    await tester.enterText(
      find.byType(TextFormField).first,
      '999999999999999999',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    expect(find.byType(AddBudgetSheet), findsOneWidget);
    expect(harness.budgetRepository.budgets, isEmpty);
  });

  testWidgets('parses a comma decimal amount', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
      newId: () => 'budget-new',
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const AddBudgetSheet()));
    await tester.enterText(find.byType(TextFormField).first, '1,23');
    await _selectCategory(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      harness.budgetRepository.budgets['budget-new']?.allocatedAmountMinorUnits,
      123,
    );
  });

  testWidgets('saves the chosen warning threshold', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
      newId: () => 'budget-new',
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const AddBudgetSheet()));
    await tester.enterText(find.byType(TextFormField).first, '10');
    await _selectCategory(tester);
    await _selectWarningThreshold(tester, '90%');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(harness.budgetRepository.budgets['budget-new']?.warningShare, 0.9);
  });

  testWidgets('defaults the warning threshold to the app default', (
    tester,
  ) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
      newId: () => 'budget-new',
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const AddBudgetSheet()));
    await tester.enterText(find.byType(TextFormField).first, '10');
    await _selectCategory(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      harness.budgetRepository.budgets['budget-new']?.warningShare,
      isNull,
    );
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
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('2026-10-01'), findsOneWidget);
    expect(find.text('Default (85%)'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '25');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      harness.budgetRepository.budgets[original.id]?.allocatedAmountMinorUnits,
      2500,
    );
    expect(harness.budgetRepository.updatedIds, <String>[original.id]);
  });

  testWidgets('pre-fills a configured threshold and can reset it', (
    tester,
  ) async {
    final original = testBudget(warningShare: 0.9);
    final harness = BudgetTestHarness(
      initialBudgets: {original.id: original},
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, AddBudgetSheet(initial: original)));
    expect(find.text('90%'), findsOneWidget);

    await _selectWarningThreshold(tester, 'Default (85%)');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(harness.budgetRepository.budgets[original.id]?.warningShare, isNull);
  });

  testWidgets('requires selecting a category when the original is invalid', (
    tester,
  ) async {
    final original = testBudget(categoryId: 'missing-category');
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, AddBudgetSheet(initial: original)));
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a valid category.'), findsOneWidget);
    expect(harness.budgetRepository.updatedIds, isEmpty);
  });

  testWidgets('keeps the sheet open when saving fails', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
    );
    harness.budgetRepository.createError = Exception('create failed');
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(_wrap(cubit, const AddBudgetSheet()));
    await tester.enterText(find.byType(TextFormField).first, '10');
    await _selectCategory(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not save the budget. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(AddBudgetSheet), findsOneWidget);
    expect(harness.budgetRepository.createdIds, isEmpty);
  });

  testWidgets('locks controls while a budget is submitting', (tester) async {
    final harness = BudgetTestHarness(
      initialCategories: {'category-1': testCategory()},
    );
    final cubit = await _loadedCubit(harness);
    harness.budgetRepository.createGate = Completer<void>();
    await tester.pumpWidget(_wrap(cubit, const AddBudgetSheet()));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.pumpAndSettle();

    final pending = cubit.createBudget(
      categoryId: 'category-1',
      allocatedAmountMinorUnits: 1000,
      period: 'monthly',
      startDate: DateTime.utc(2026, 10),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.isSubmitting, isTrue);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      equals('10'),
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).enabled,
      isFalse,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>).first,
          )
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>).last,
          )
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );

    harness.budgetRepository.createGate!.complete();
    await pending;
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

  testWidgets('closes the no-category sheet', (tester) async {
    final harness = BudgetTestHarness();
    final cubit = await _loadedCubit(harness);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () {
                    unawaited(
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (sheetContext) =>
                            BlocProvider<BudgetCubit>.value(
                              value: cubit,
                              child: const AddBudgetSheet(),
                            ),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('No categories yet'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AddBudgetSheet), findsNothing);
  });
}
