import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/app/router/screens/placeholder_screen.dart';
import 'package:finecho/features/onboarding/view/screens/onboarding_screen.dart';
import 'package:finecho/features/onboarding/view/screens/security_setup_screen.dart';
import 'package:finecho/features/onboarding/view/screens/welcome_screen.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Configures the initial application navigation graph.
class AppRouter {
  /// Creates the application router.
  new({OnboardingCubit? onboardingCubit}) {
    final cubit = onboardingCubit ?? sl<OnboardingCubit>();
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
          builder: (context, state) => BlocProvider<OnboardingCubit>.value(
            value: cubit,
            child: const SecuritySetupScreen(),
          ),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const PlaceholderScreen(title: 'Home'),
        ),
        GoRoute(
          path: '/accounts',
          name: 'accounts',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Accounts'),
        ),
        GoRoute(
          path: '/statistics',
          name: 'statistics',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Statistics'),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Settings'),
        ),
      ],
    );
  }

  /// The application navigation state.
  late final GoRouter router;
}
