import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The primary navigation shell for the main app destinations.
///
/// Hosts the home, budgets, and statistics branches under a bottom
/// navigation bar so every primary screen has an in-app entry point.
class HomeShell extends StatelessWidget {
  /// Creates the shell that displays [navigationShell] branches.
  const new({required this.navigationShell, super.key});

  /// The stateful navigation shell that owns the branch destinations.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }
}
