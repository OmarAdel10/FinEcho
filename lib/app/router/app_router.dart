import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/app/router/screens/placeholder_screen.dart';
import 'package:finecho/features/analytics/view/screens/analytics_screen.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/budget/view/screens/budget_screen.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/onboarding/view/screens/onboarding_screen.dart';
import 'package:finecho/features/onboarding/view/screens/security_setup_screen.dart';
import 'package:finecho/features/onboarding/view/screens/welcome_screen.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/security/view/widgets/security_gate.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/transactions/view/screens/transactions_screen.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Configures the initial application navigation graph.
class AppRouter {
  /// Creates the application router.
  new({
    OnboardingCubit? onboardingCubit,
    SecurityCubit? securityCubit,
    TransactionsCubit? transactionsCubit,
    BudgetCubit? budgetCubit,
    AnalyticsCubit? analyticsCubit,
  }) {
    final cubit = onboardingCubit ?? sl<OnboardingCubit>();
    final security = securityCubit ?? sl<SecurityCubit>();
    final transactions = transactionsCubit ?? sl<TransactionsCubit>();
    final budgets = budgetCubit ?? sl<BudgetCubit>();
    final analytics = analyticsCubit ?? sl<AnalyticsCubit>();
    _securityCubit = security;
    _transactionsCubit = transactions;
    _budgetsCubit = budgets;
    _analyticsCubit = analytics;
    router = GoRouter(
      initialLocation: '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (context, state) => BlocProvider<OnboardingCubit>.value(
            value: cubit,
            child: const WelcomeScreen(),
          ),
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => BlocProvider<OnboardingCubit>.value(
            value: cubit,
            child: const OnboardingScreen(),
          ),
        ),
        GoRoute(
          path: '/security-setup',
          name: 'security-setup',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<OnboardingCubit>.value(value: cubit),
              BlocProvider<SecurityCubit>.value(value: security),
            ],
            child: const SecuritySetupScreen(),
          ),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => _protected(
            BlocProvider<TransactionsCubit>.value(
              value: _transactionsCubit,
              child: const TransactionsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/budgets',
          name: 'budgets',
          builder: (context, state) => _protected(
            BlocProvider<BudgetCubit>.value(
              value: _budgetsCubit,
              child: const BudgetScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/accounts',
          name: 'accounts',
          builder: (context, state) =>
              _protected(const PlaceholderScreen(title: 'Accounts')),
        ),
        GoRoute(
          path: '/statistics',
          name: 'statistics',
          builder: (context, state) => _protected(
            BlocProvider<AnalyticsCubit>.value(
              value: _analyticsCubit,
              child: const AnalyticsScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) =>
              _protected(const PlaceholderScreen(title: 'Settings')),
        ),
      ],
    );
  }

  /// The application navigation state.
  late final GoRouter router;

  late final SecurityCubit _securityCubit;

  late final TransactionsCubit _transactionsCubit;

  late final BudgetCubit _budgetsCubit;

  late final AnalyticsCubit _analyticsCubit;

  Widget _protected(Widget child) {
    return BlocProvider<SecurityCubit>.value(
      value: _securityCubit,
      child: SecurityGate(child: child),
    );
  }
}
