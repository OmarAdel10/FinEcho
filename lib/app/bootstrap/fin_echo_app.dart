import 'package:finecho/app/theme/fin_echo_theme.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/security/view/widgets/security_lifecycle_observer.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The root FinEcho application widget.
class FinEchoApp extends StatelessWidget {
  /// Creates the root application widget.
  const new({
    required this.router,
    this.securityCubit,
    this.analyticsCubit,
    this.transactionsCubit,
    super.key,
  }) : assert(
         securityCubit == null || analyticsCubit != null,
         'FinEchoApp needs an analyticsCubit when a securityCubit is wired '
         'so clearCachedDashboard can be called on lock.',
       );

  /// The navigation configuration for the app.
  final GoRouter router;

  /// The app-lock ViewModel, when the app should relock on backgrounding.
  final SecurityCubit? securityCubit;

  /// The analytics ViewModel, when the app should drop cached aggregates
  /// whenever the app lock engages.
  final AnalyticsCubit? analyticsCubit;

  /// The transactions ViewModel, when the app should drop the cached ledger
  /// whenever the app lock engages.
  final TransactionsCubit? transactionsCubit;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      title: 'FinEcho',
      theme: FinEchoTheme.light(),
      darkTheme: FinEchoTheme.dark(),
      routerConfig: router,
    );
    final cubit = securityCubit;
    if (cubit == null) {
      return app;
    }
    final analytics = analyticsCubit;
    final transactions = transactionsCubit;
    return SecurityLifecycleObserver(
      cubit: cubit,
      onLock: () {
        analytics?.clearCachedDashboard();
        transactions?.clearCachedLedger();
      },
      child: app,
    );
  }
}
