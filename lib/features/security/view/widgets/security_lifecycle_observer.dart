import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';

/// Relocks the app when it is backgrounded.
///
/// The observer lives at app scope, so the app relocks even when no protected
/// screen is mounted and a single observer serves the whole app. The hook
/// re-fires on every pause that leaves the lock engaged: clearing is
/// idempotent, and a lock that engages without a pause is cleared by the
/// next one.
class SecurityLifecycleObserver extends StatefulWidget {
  /// Creates an observer that relocks [cubit] when the app is paused and
  /// runs [onLock] when the lock engages.
  const new({required this.cubit, required this.child, this.onLock, super.key});

  /// The app-lock ViewModel.
  final SecurityCubit cubit;

  /// Called on every app lifecycle pause that leaves the lock engaged;
  /// repeated pauses re-run it by design.
  final VoidCallback? onLock;

  /// The subtree that observes the app lifecycle.
  final Widget child;

  @override
  State<SecurityLifecycleObserver> createState() =>
      _SecurityLifecycleObserverState();
}

class _SecurityLifecycleObserverState extends State<SecurityLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.cubit.lock();
      if (widget.cubit.state.isLocked) {
        // Re-fires on every locked pause on purpose: the clear is
        // idempotent, and a lock that engaged without a pause (a PIN
        // configured while a dashboard was cached) is cleared here.
        widget.onLock?.call();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
