import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/app/router/screens/placeholder_screen.dart';
import 'package:finecho/features/analytics/view/screens/analytics_screen.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/budget/view/screens/budget_screen.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/onboarding/data/models/onboarding_step.dart';
import 'package:finecho/features/onboarding/view/screens/onboarding_screen.dart';
import 'package:finecho/features/onboarding/view/screens/security_setup_screen.dart';
import 'package:finecho/features/onboarding/view/screens/welcome_screen.dart';
import 'package:finecho/features/onboarding/view_model/models/onboarding_state.dart';
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

    final securityAccess = security.state;
    final startProtected =
        securityAccess.hasLoadError ||
        (securityAccess.securityState.appLockEnabled &&
            securityAccess.securityState.pinConfigured);

    // Determine the correct initial location based on onboarding state
    final onboardingState = cubit.state;
    final initialLocation = _resolveInitialLocation(
      onboardingState,
      startProtected,
    );

    router = GoRouter(
      initialLocation: initialLocation,
      redirect: (context, state) {
        final access = _securityCubit.state;
        final configured =
            access.securityState.appLockEnabled &&
            access.securityState.pinConfigured;
        if (!configured) {
          return null;
        }
        final path = state.uri.path;
        if (path == '/welcome' ||
            path == '/onboarding' ||
            path == '/security-setup') {
          return '/home';
        }
        return null;
      },
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

  /// Resolves the initial route based on onboarding and security state.
  static String _resolveInitialLocation(
    OnboardingState onboardingState,
    bool startProtected,
  ) {
    // If app is locked, go to home (security gate will handle unlock)
    if (startProtected) {
      return '/home';
    }

    // If onboarding is completed, go to home
    if (onboardingState.status == OnboardingStatus.completed) {
      return '/home';
    }

    // If onboarding is in progress, resume at the appropriate step
    if (onboardingState.status == OnboardingStatus.ready) {
      // Resume at security setup if that's where the user left off
      if (onboardingState.currentStep == OnboardingStep.securitySetup) {
        return '/security-setup';
      }
      // Resume at onboarding for other incomplete steps
      if (onboardingState.currentStep.index <
          OnboardingStep.automation.index + 1) {
        return '/onboarding';
      }
    }

    // Default to welcome for new users
    return '/welcome';
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
