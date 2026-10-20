import 'dart:async';

import 'package:finecho/features/security/view/screens/lock_screen.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Hides protected app content until the configured app lock is satisfied.
class SecurityGate extends StatefulWidget {
  /// Creates a security gate around [child].
  const new({required this.child, super.key});

  /// The protected content.
  final Widget child;

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate>
    with WidgetsBindingObserver {
  late final SecurityCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<SecurityCubit>();
    WidgetsBinding.instance.addObserver(this);
    if (_cubit.state.status == SecurityAccessStatus.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_cubit.load());
        }
      });
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase app data?'),
        content: const Text(
          'This removes the saved PIN and app-lock settings from this device. '
          'You will set up the app again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Erase app data'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final reset = await _cubit.resetLock();
      if (!reset || !mounted) {
        return;
      }
      // The app lock is gone, so send the user back into onboarding instead
      // of leaving the protected area without a way to set the lock again.
      GoRouter.maybeOf(context)?.go('/welcome');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _cubit.lock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityCubit, SecurityAccessState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state.status == SecurityAccessStatus.loading ||
            (state.status == SecurityAccessStatus.submitting &&
                !state.isLocked)) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.hasLoadError) {
          return _SecurityLoadFailure(
            message:
                state.errorMessage ??
                'Could not load security settings. Please try again.',
            onRetry: () => unawaited(_cubit.load()),
            onReset: _confirmReset,
          );
        }
        if (state.isLocked) {
          return const LockScreen();
        }
        return widget.child;
      },
    );
  }
}

class _SecurityLoadFailure extends StatelessWidget {
  const new({
    required this.message,
    required this.onRetry,
    required this.onReset,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FinEcho')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Security settings unavailable',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onReset,
                  child: const Text('Erase app data'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
