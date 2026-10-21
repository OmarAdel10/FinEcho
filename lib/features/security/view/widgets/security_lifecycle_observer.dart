import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';

/// Relocks the app when it is backgrounded.
///
/// The observer lives at app scope, so the app relocks even when no protected
/// screen is mounted and a single observer serves the whole app.
class SecurityLifecycleObserver extends StatefulWidget {
  /// Creates an observer that relocks [cubit] when the app is paused.
  const new({required this.cubit, required this.child, super.key});

  /// The app-lock ViewModel.
  final SecurityCubit cubit;

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
