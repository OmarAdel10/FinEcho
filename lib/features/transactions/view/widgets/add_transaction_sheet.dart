import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/transactions/view_model/models/transactions_state.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String _invalidAmountMessage = 'Enter an amount greater than zero.';
const String _amountLabel = 'Amount';
const String _accountLabel = 'Account';
const String _invalidAccountMessage = 'Choose a valid account.';
const String _categoryLabel = 'Category';
const String _uncategorizedLabel = 'Uncategorized';
const String _noteLabel = 'Note (optional)';
const String _saveLabel = 'Save';
const String _expenseLabel = 'Expense';
const String _incomeLabel = 'Income';
const String _transferLabel = 'Transfer';
const String _closeLabel = 'Close';
const String _noAccountsTitle = 'No accounts yet';
const String _noAccountsMessage =
    'Add an account to start tracking transactions.';
const String _savingFailedMessage =
    'Could not save the transaction. Please try again.';

/// The create or edit transaction form shown as a modal sheet.
class AddTransactionSheet extends StatefulWidget {
  /// Creates the transaction form.
  const new({this.initial, super.key});

  /// The transaction being edited, or null when creating.
  final Transaction? initial;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  String? _accountId;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _amountController = TextEditingController(
      text: initial == null ? '' : _formatMinorUnits(initial.amountMinorUnits),
    );
    _noteController = TextEditingController(text: initial?.rawText ?? '');
    _type = initial?.type ?? TransactionType.expense;
    _accountId = initial?.accountId;
    _categoryId = initial?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        if (state.accounts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _noAccountsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(_noAccountsMessage),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(_closeLabel),
                ),
              ],
            ),
          );
        }

        _syncSelectedIds(state);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: _amountLabel),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[.,]?\d{0,2}$'),
                      ),
                    ],
                    validator: (_) {
                      if (_parseMinorUnits(_amountController.text) == null) {
                        return _invalidAmountMessage;
                      }
                      return null;
                    },
                    enabled: !state.isSubmitting,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text(_expenseLabel),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text(_incomeLabel),
                      ),
                      ButtonSegment(
                        value: TransactionType.transfer,
                        label: Text(_transferLabel),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: state.isSubmitting
                        ? null
                        : (selection) {
                            final type = selection.first;
                            setState(() {
                              _type = type;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _accountId,
                    decoration: const InputDecoration(labelText: _accountLabel),
                    items: state.accounts
                        .map(
                          (account) => DropdownMenuItem<String>(
                            value: account.id,
                            child: Text(account.name),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        value == null ? _invalidAccountMessage : null,
                    onChanged: state.isSubmitting
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _accountId = value;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: _categoryLabel,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        child: Text(_uncategorizedLabel),
                      ),
                      ...state.categories.map(
                        (category) => DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      ),
                    ],
                    onChanged: state.isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _categoryId = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: _noteLabel),
                    enabled: !state.isSubmitting,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: state.isSubmitting ? null : _submit,
                    child: const Text(_saveLabel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final amount = _parseMinorUnits(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(_invalidAmountMessage)));
      return;
    }

    final cubit = context.read<TransactionsCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final note = _noteController.text.trim();
    final noteOrNull = note.isEmpty ? null : note;
    final accountId = _accountId;
    final initial = widget.initial;
    final ok = initial == null
        ? await cubit.addTransaction(
            accountId: accountId!,
            type: _type,
            amountMinorUnits: amount,
            categoryId: _categoryId,
            note: noteOrNull,
          )
        : await cubit.updateTransaction(
            original: initial,
            accountId: accountId!,
            type: _type,
            amountMinorUnits: amount,
            categoryId: _categoryId,
            note: noteOrNull,
          );
    if (!mounted) {
      return;
    }
    if (ok) {
      navigator.pop();
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(cubit.state.errorMessage ?? _savingFailedMessage)),
    );
  }

  void _syncSelectedIds(TransactionsState state) {
    final accountIds = state.accounts.map((account) => account.id).toList();
    if (!accountIds.contains(_accountId)) {
      _accountId = accountIds.first;
    }
    final categoryIds = state.categories
        .map((category) => category.id)
        .toList();
    if (_categoryId != null && !categoryIds.contains(_categoryId)) {
      _categoryId = null;
    }
  }

  int? _parseMinorUnits(String input) {
    final value = input.trim();
    if (!RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(value)) {
      return null;
    }

    final separator = RegExp('[.,]').firstMatch(value);
    final majorText = separator == null
        ? value
        : value.substring(0, separator.start);
    final fractionText = separator == null
        ? ''
        : value.substring(separator.start + 1);
    final major = int.parse(majorText);
    final fraction = int.parse(fractionText.padRight(2, '0'));
    final minorUnits = major * 100 + fraction;
    return minorUnits <= 0 ? null : minorUnits;
  }

  String _formatMinorUnits(int amountMinorUnits) {
    final major = amountMinorUnits ~/ 100;
    final fraction = (amountMinorUnits % 100).toString().padLeft(2, '0');
    return '$major.$fraction';
  }
}
