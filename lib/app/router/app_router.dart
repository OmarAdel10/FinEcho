import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/app/router/screens/placeholder_screen.dart';
import 'package:finecho/features/onboarding/view/screens/onboarding_screen.dart';
import 'package:finecho/features/onboarding/view/screens/security_setup_screen.dart';
import 'package:finecho/features/onboarding/view/screens/welcome_screen.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/security/view/widgets/security_gate.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Configures the initial application navigation graph.
class AppRouter {
  /// Creates the application router.
  new({OnboardingCubit? onboardingCubit, SecurityCubit? securityCubit}) {
    final cubit = onboardingCubit ?? sl<OnboardingCubit>();
    final security = securityCubit ?? sl<SecurityCubit>();
    _securityCubit = security;
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
          builder: (context, state) =>
              _protected(const PlaceholderScreen(title: 'Home')),
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
          builder: (context, state) =>
              _protected(const PlaceholderScreen(title: 'Statistics')),
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

  Widget _protected(Widget child) {
    return BlocProvider<SecurityCubit>.value(
      value: _securityCubit,
      child: SecurityGate(child: child),
    );
  }
}
