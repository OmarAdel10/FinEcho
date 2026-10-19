import 'dart:async';

import 'package:finecho/features/analytics/view/widgets/account_breakdown_card.dart';
import 'package:finecho/features/analytics/view/widgets/analytics_summary_card.dart';
import 'package:finecho/features/analytics/view/widgets/budget_progress_card.dart';
import 'package:finecho/features/analytics/view/widgets/category_breakdown_card.dart';
import 'package:finecho/features/analytics/view/widgets/insights_card.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_period.dart';
import 'package:finecho/features/analytics/view_model/models/analytics_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const String _appBarTitle = 'FinEcho';
const String _weeklyLabel = 'Weekly';
const String _monthlyLabel = 'Monthly';
const String _yearlyLabel = 'Yearly';
const String _failureTitle = 'Something went wrong';
const String _tryAgainLabel = 'Try again';

/// The statistics dashboard screen.
class AnalyticsScreen extends StatefulWidget {
  /// Creates the analytics screen.
  const new({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(context.read<AnalyticsCubit>().load());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_appBarTitle)),
      body: SafeArea(
        child: BlocBuilder<AnalyticsCubit, AnalyticsState>(
          builder: (context, state) {
            final dashboard = state.dashboard;
            if (dashboard == null && state.status == AnalyticsStatus.failure) {
              return _FailureState(
                onRetry: () {
                  unawaited(context.read<AnalyticsCubit>().load());
                },
              );
            }
            if (dashboard == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: context.read<AnalyticsCubit>().load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SegmentedButton<AnalyticsPeriod>(
                    segments: const [
                      ButtonSegment(
                        value: AnalyticsPeriod.week,
                        label: Text(_weeklyLabel),
                      ),
                      ButtonSegment(
                        value: AnalyticsPeriod.month,
                        label: Text(_monthlyLabel),
                      ),
                      ButtonSegment(
                        value: AnalyticsPeriod.year,
                        label: Text(_yearlyLabel),
                      ),
                    ],
                    selected: {state.period},
                    onSelectionChanged: (selection) {
                      unawaited(
                        context.read<AnalyticsCubit>().selectPeriod(
                          selection.first,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AnalyticsSummaryCard(
                    totalIncomeMinorUnits: dashboard.totalIncomeMinorUnits,
                    totalExpenseMinorUnits: dashboard.totalExpenseMinorUnits,
                    netAmountMinorUnits: dashboard.netAmountMinorUnits,
                    expenseChangeRatio: dashboard.expenseChangeRatio,
                  ),
                  const SizedBox(height: 12),
                  CategoryBreakdownCard(
                    categoryTotals: dashboard.categoryTotals,
                  ),
                  const SizedBox(height: 12),
                  AccountBreakdownCard(accountTotals: dashboard.accountTotals),
                  const SizedBox(height: 12),
                  InsightsCard(
                    forecast: dashboard.forecast,
                    recurringCharges: dashboard.recurringCharges,
                    unusualSpikes: dashboard.unusualSpikes,
                  ),
                  if (dashboard.budgetProgress.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    BudgetProgressCard(
                      budgetProgress: dashboard.budgetProgress,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
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
