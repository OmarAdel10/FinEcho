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

class _SecurityGateState extends State<SecurityGate> {
  late final SecurityCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<SecurityCubit>();
    if (_cubit.state.status == SecurityAccessStatus.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_loadAndRoute());
        }
      });
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erase app lock?'),
        content: const Text(
          'This removes the saved PIN and app-lock settings from this device. '
          'You will set the app lock up again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Erase app lock'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _cubit.resetLock();
      if (!mounted) {
        return;
      }
      _goToSetupWhenUnconfigured();
    }
  }

  /// Reloads the persisted lock state.
  ///
  /// A reload started from the recovery screen must send the user back to
  /// setup when the store is readable but no lock is configured any more. A
  /// reload started on a normal start must never move the user away from the
  /// route they opened.
  Future<void> _loadAndRoute({bool fromRecovery = false}) async {
    await _cubit.load();
    if (!mounted) {
      return;
    }
    if (fromRecovery) {
      _goToSetupWhenUnconfigured();
    }
  }

  /// Sends the user back into onboarding when the app lock is gone, so the
  /// protected area never stays reachable without a way to set the lock up.
  void _goToSetupWhenUnconfigured() {
    final access = _cubit.state;
    final security = access.securityState;
    final configured = security.appLockEnabled && security.pinConfigured;
    if (configured || access.status == SecurityAccessStatus.error) {
      return;
    }
    GoRouter.maybeOf(context)?.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityCubit, SecurityAccessState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state.status == SecurityAccessStatus.loading ||
            state.status == SecurityAccessStatus.resetting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.hasLoadError) {
          return _SecurityLoadFailure(
            message:
                state.errorMessage ??
                'Could not load security settings. Please try again.',
            onRetry: () => unawaited(_loadAndRoute(fromRecovery: true)),
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
                  child: const Text('Erase app lock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
