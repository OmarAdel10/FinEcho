import 'dart:async';

import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/core/models/category.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/transactions/view/widgets/add_transaction_sheet.dart';
import 'package:finecho/features/transactions/view/widgets/period_totals_card.dart';
import 'package:finecho/features/transactions/view/widgets/transaction_tile.dart';
import 'package:finecho/features/transactions/view_model/models/period_totals.dart';
import 'package:finecho/features/transactions/view_model/models/transactions_state.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String _appBarTitle = 'FinEcho';
const String _addTransactionLabel = 'Add transaction';
const String _noAccountsTitle = 'No accounts yet';
const String _noAccountsMessage =
    'Add an account to start tracking transactions.';
const String _noTransactionsTitle = 'No transactions yet';
const String _noTransactionsMessage =
    'Tap Add transaction to record your first entry.';
const String _failureTitle = 'Something went wrong';
const String _tryAgainLabel = 'Try again';
const String _deleteTitle = 'Delete transaction?';
const String _deleteMessage = 'This removes the transaction permanently.';
const String _cancelLabel = 'Cancel';
const String _deleteLabel = 'Delete';

/// The FinEcho transaction list and manual-entry entry point.
class TransactionsScreen extends StatefulWidget {
  /// Creates the transaction screen.
  const new({super.key, this.now, this.localUtcOffset});

  /// Resolves the current instant for the period totals.
  ///
  /// Defaults to the wall clock. Tests pin it so period boundaries are
  /// machine independent.
  final DateTime Function()? now;

  /// The local UTC offset used for period boundaries.
  ///
  /// Defaults to the device offset. Tests pin it to [Duration.zero].
  final Duration? localUtcOffset;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final cubit = context.read<TransactionsCubit>();
      if (cubit.state.status == TransactionsStatus.loading) {
        unawaited(cubit.load());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_appBarTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          unawaited(_showTransactionSheet());
        },
        icon: const Icon(Icons.add),
        label: const Text(_addTransactionLabel),
      ),
      body: BlocConsumer<TransactionsCubit, TransactionsState>(
        listenWhen: (previous, current) =>
            previous.status != TransactionsStatus.failure &&
            current.status == TransactionsStatus.failure,
        listener: (context, state) {
          final errorMessage = state.errorMessage;
          if (errorMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(errorMessage)));
          }
        },
        builder: (context, state) {
          if (state.accounts.isEmpty &&
              state.transactions.isEmpty &&
              state.status != TransactionsStatus.loading &&
              state.status != TransactionsStatus.failure) {
            return const _BlockedEmptyState();
          }
          if (state.status == TransactionsStatus.failure &&
              state.transactions.isEmpty) {
            return _FailureState(
              onRetry: () {
                unawaited(context.read<TransactionsCubit>().load());
              },
            );
          }
          if (state.status == TransactionsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.transactions.isEmpty) {
            return const _EmptyTransactionsState();
          }

          final resolvedNow = (widget.now ?? DateTime.now)().toUtc();
          final resolvedOffset =
              widget.localUtcOffset ?? DateTime.now().timeZoneOffset;
          final totals = computePeriodTotals(
            transactions: state.transactions,
            period: _selectedPeriod,
            now: resolvedNow,
            localUtcOffset: resolvedOffset,
          );

          // Determine primary currency from the first account
          final primaryCurrency = state.accounts.isNotEmpty
              ? state.accounts.first.currency
              : null;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: PeriodTotalsCard(
                    totals: totals,
                    selectedPeriod: _selectedPeriod,
                    onPeriodSelected: (period) {
                      setState(() => _selectedPeriod = period);
                    },
                    localUtcOffset: resolvedOffset,
                    currency: primaryCurrency,
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = state.transactions[index];
                      final categoryName = _categoryName(
                        state.categories,
                        transaction.categoryId,
                      );
                      final tile = TransactionTile(
                        transaction: transaction,
                        categoryName: categoryName,
                        onTap: () {
                          unawaited(
                            _showTransactionSheet(initial: transaction),
                          );
                        },
                      );
                      if (state.status != TransactionsStatus.ready) {
                        return tile;
                      }
                      return Dismissible(
                        key: ValueKey(transaction.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(transaction),
                        child: tile,
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showTransactionSheet({Transaction? initial}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider<TransactionsCubit>.value(
        value: context.read<TransactionsCubit>(),
        child: AddTransactionSheet(initial: initial),
      ),
    );
  }

  Future<bool> _confirmDelete(Transaction transaction) async {
    final cubit = context.read<TransactionsCubit>();
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

    await cubit.deleteTransaction(transaction.id);
    return true;
  }

  String? _categoryName(List<Category> categories, String? categoryId) {
    if (categoryId == null) {
      return null;
    }
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
          Text(
            _noAccountsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(_noAccountsMessage, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 48),
          const SizedBox(height: 12),
          Text(
            _noTransactionsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(_noTransactionsMessage, textAlign: TextAlign.center),
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
