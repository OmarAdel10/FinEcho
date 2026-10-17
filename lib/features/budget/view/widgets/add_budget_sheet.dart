import 'package:finecho/core/models/budget.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/budget/view_model/models/budget_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String _invalidAmountMessage = 'Enter an amount greater than zero.';
const String _amountLabel = 'Allocated amount';
const String _categoryLabel = 'Category';
const String _periodLabel = 'Period';
const String _startDateLabel = 'Start date';
const String _saveLabel = 'Save';
const String _closeLabel = 'Close';
const String _savingFailedMessage =
    'Could not save the budget. Please try again.';

/// The create or edit budget form shown as a modal sheet.
class AddBudgetSheet extends StatefulWidget {
  /// Creates the budget form.
  const new({this.initial, super.key});

  /// The budget being edited, or null when creating.
  final Budget? initial;

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late String _period;
  late DateTime _startDate;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _amountController = TextEditingController(
      text: initial == null
          ? ''
          : _formatMinorUnits(initial.allocatedAmountMinorUnits),
    );
    _period = initial?.period.name ?? 'monthly';
    _startDate = initial?.startDate ?? DateTime.now();
    _categoryId = initial?.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetCubit, BudgetState>(
      builder: (context, state) {
        if (state.categories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'No categories yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text('Add a category before creating a budget.'),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(_closeLabel),
                ),
              ],
            ),
          );
        }

        _syncSelectedCategory(state);
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
                  DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: _categoryLabel,
                    ),
                    items: state.categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    validator: (value) =>
                        value == null ? 'Choose a valid category.' : null,
                    onChanged: state.isSubmitting
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _categoryId = value;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _period,
                    decoration: const InputDecoration(labelText: _periodLabel),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Monthly'),
                      ),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    ],
                    onChanged: state.isSubmitting
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _period = value;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text(_startDateLabel),
                    subtitle: Text(_formatDate(_startDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: state.isSubmitting
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null && mounted) {
                              setState(() {
                                _startDate = picked;
                              });
                            }
                          },
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

    final cubit = context.read<BudgetCubit>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final categoryId = _categoryId;
    final initial = widget.initial;
    final ok = initial == null
        ? await cubit.createBudget(
            categoryId: categoryId!,
            allocatedAmountMinorUnits: amount,
            period: _period,
            startDate: _startDate,
          )
        : await cubit.updateBudget(
            original: initial,
            categoryId: categoryId!,
            allocatedAmountMinorUnits: amount,
            period: _period,
            startDate: _startDate,
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

  void _syncSelectedCategory(BudgetState state) {
    final categoryIds = state.categories.map((c) => c.id).toList();
    if (_categoryId != null && !categoryIds.contains(_categoryId)) {
      _categoryId = categoryIds.first;
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

  String _formatDate(DateTime timestamp) {
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    return '${timestamp.year}-$month-$day';
  }
}
