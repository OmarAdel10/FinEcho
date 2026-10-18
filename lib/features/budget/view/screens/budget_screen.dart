import 'dart:async';

import 'package:finecho/core/models/budget.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/features/budget/view/widgets/add_budget_sheet.dart';
import 'package:finecho/features/budget/view/widgets/budget_tile.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/budget/view_model/models/budget_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String _appBarTitle = 'FinEcho';
const String _addBudgetLabel = 'Add budget';
const String _noBudgetsTitle = 'No budgets yet';
const String _noBudgetsMessage =
    'Tap Add budget to set a spending limit for a category.';
const String _failureTitle = 'Something went wrong';
const String _tryAgainLabel = 'Try again';
const String _deleteTitle = 'Delete budget?';
const String _deleteMessage = 'This removes the budget permanently.';
const String _cancelLabel = 'Cancel';
const String _deleteLabel = 'Delete';

/// The FinEcho budget list and entry point.
class BudgetScreen extends StatefulWidget {
  /// Creates the budget screen.
  const new({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(context.read<BudgetCubit>().load());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_appBarTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          unawaited(_showBudgetSheet());
        },
        icon: const Icon(Icons.add),
        label: const Text(_addBudgetLabel),
      ),
      body: BlocConsumer<BudgetCubit, BudgetState>(
        listenWhen: (previous, current) =>
            previous.status != BudgetStatus.failure &&
            current.status == BudgetStatus.failure,
        listener: (context, state) {
          final errorMessage = state.errorMessage;
          if (errorMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(errorMessage)));
          }
        },
        builder: (context, state) {
          if (state.categories.isEmpty &&
              state.budgets.isEmpty &&
              state.status != BudgetStatus.loading &&
              state.status != BudgetStatus.failure) {
            return const _BlockedEmptyState();
          }
          if (state.status == BudgetStatus.failure && state.budgets.isEmpty) {
            return _FailureState(
              onRetry: () {
                unawaited(context.read<BudgetCubit>().load());
              },
            );
          }
          if (state.status == BudgetStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.budgets.isEmpty) {
            return const _EmptyBudgetsState();
          }

          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.budgets.length,
              itemBuilder: (context, index) {
                final budget = state.budgets[index];
                final categoryName = _categoryName(
                  state.categories,
                  budget.categoryId,
                );
                final tile = BudgetTile(
                  budget: budget,
                  categoryName: categoryName,
                  onTap: () {
                    unawaited(_showBudgetSheet(initial: budget));
                  },
                );
                if (state.status != BudgetStatus.ready) {
                  return tile;
                }
                return Dismissible(
                  key: ValueKey(budget.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(budget),
                  child: tile,
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 4),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBudgetSheet({Budget? initial}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider<BudgetCubit>.value(
        value: context.read<BudgetCubit>(),
        child: AddBudgetSheet(initial: initial),
      ),
    );
  }

  Future<bool> _confirmDelete(Budget budget) async {
    final cubit = context.read<BudgetCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(_deleteTitle),
          content: const Text(_deleteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(_cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(_deleteLabel),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return false;
    }

    await cubit.deleteBudget(budget.id);
    return true;
  }

  String? _categoryName(List<Category> categories, String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return null;
  }
}

class _BlockedEmptyState extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 48),
          const SizedBox(height: 12),
          Text(_noBudgetsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(_noBudgetsMessage, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EmptyBudgetsState extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 48),
          const SizedBox(height: 12),
          Text(_noBudgetsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(_noBudgetsMessage, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FailureState extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_failureTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text(_tryAgainLabel)),
        ],
      ),
    );
  }
}
