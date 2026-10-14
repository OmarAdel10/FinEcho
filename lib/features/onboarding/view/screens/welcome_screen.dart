import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The first-run entry point for FinEcho onboarding.
class WelcomeScreen extends StatelessWidget {
  /// Creates the welcome screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.savings_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to FinEcho',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Keep your money visible, organized, and private on this '
                'device.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('Get started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
