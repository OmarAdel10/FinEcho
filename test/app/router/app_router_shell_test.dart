import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/analytics/view/screens/analytics_screen.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/budget/view/screens/budget_screen.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/security/view/screens/lock_screen.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/transactions/view/screens/transactions_screen.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/fake_analytics_repositories.dart';
import '../../features/budget/fake_budget_repositories.dart';
import '../../features/onboarding/fake_onboarding_repository.dart';
import '../../features/security/fake_security_repositories.dart';
import '../../features/transactions/fake_transaction_repositories.dart';

void main() {
  testWidgets('shows the primary destinations in the navigation shell', (
    tester,
  ) async {
    final harness = _unlockedRouter();
    addTearDown(harness.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: harness.router));
    harness.router.go('/home');
    await tester.pump();
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.byType(TransactionsScreen), findsOneWidget);
  });

  testWidgets('switches to the budgets destination', (tester) async {
    final harness = _unlockedRouter();
    addTearDown(harness.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: harness.router));
    harness.router.go('/home');
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Budgets'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(BudgetScreen), findsOneWidget);
    expect(find.byType(TransactionsScreen), findsNothing);
  });

  testWidgets('switches to the statistics destination', (tester) async {
    final harness = _unlockedRouter();
    addTearDown(harness.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: harness.router));
    harness.router.go('/home');
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Statistics'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AnalyticsScreen), findsOneWidget);
    expect(find.byType(TransactionsScreen), findsNothing);
  });

  testWidgets('hides the navigation shell behind the app lock', (tester) async {
    final now = DateTime.utc(2026, 10, 15, 12);
    final securityHarness = SecurityTestHarness(
      initialState: SecurityState(
        appLockEnabled: true,
        pinConfigured: true,
        failedUnlockAttempts: 0,
        secureKeyReady: true,
        updatedAt: now,
      ),
      now: () => now,
    );
    await securityHarness.credentialRepository.savePin('123456');
    final securityCubit = SecurityCubit(securityHarness.service);
    final onboardingCubit = OnboardingCubit(
      OnboardingService(FakeOnboardingRepository()),
    );
    final transactionsCubit = TransactionsCubit(
      TransactionsTestHarness().service,
    );
    final budgetCubit = BudgetCubit(BudgetTestHarness().service);
    final analyticsCubit = AnalyticsCubit(AnalyticsTestHarness().service);
    final appRouter = AppRouter(
      onboardingCubit: onboardingCubit,
      securityCubit: securityCubit,
      transactionsCubit: transactionsCubit,
      budgetCubit: budgetCubit,
      analyticsCubit: analyticsCubit,
    );
    final router = appRouter.router;
    addTearDown(router.dispose);
    addTearDown(onboardingCubit.close);
    addTearDown(securityCubit.close);
    addTearDown(transactionsCubit.close);
    addTearDown(budgetCubit.close);
    addTearDown(analyticsCubit.close);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/home');
    await tester.pump();
    await tester.pump();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}

class _RouterHarness {
  new(this.router, this._closers);

  final GoRouter router;
  final List<void Function()> _closers;

  void dispose() {
    router.dispose();
    for (final close in _closers) {
      close();
    }
  }
}

_RouterHarness _unlockedRouter() {
  final now = DateTime.utc(2026, 10, 15, 12);
  final securityHarness = SecurityTestHarness(
    initialState: SecurityState(
      appLockEnabled: false,
      pinConfigured: false,
      failedUnlockAttempts: 0,
      secureKeyReady: true,
      updatedAt: now,
    ),
    now: () => now,
  );
  final securityCubit = SecurityCubit(securityHarness.service);
  final onboardingCubit = OnboardingCubit(
    OnboardingService(FakeOnboardingRepository()),
  );
  final transactionsCubit = TransactionsCubit(
    TransactionsTestHarness().service,
  );
  final budgetCubit = BudgetCubit(BudgetTestHarness().service);
  final analyticsCubit = AnalyticsCubit(AnalyticsTestHarness().service);
  final appRouter = AppRouter(
    onboardingCubit: onboardingCubit,
    securityCubit: securityCubit,
    transactionsCubit: transactionsCubit,
    budgetCubit: budgetCubit,
    analyticsCubit: analyticsCubit,
  );
  return _RouterHarness(appRouter.router, [
    onboardingCubit.close,
    securityCubit.close,
    transactionsCubit.close,
    budgetCubit.close,
    analyticsCubit.close,
  ]);
}
