import 'package:finecho/app/router/screens/placeholder_screen.dart';
import 'package:go_router/go_router.dart';

/// Configures the initial application navigation graph.
class AppRouter {
  /// Creates the application router.
  new() {
    router = GoRouter(
      initialLocation: '/home',
      routes: [
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
