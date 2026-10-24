import 'package:finecho/app/di/service_locator.dart';
import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/core/models/analytics_period.dart';
import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/analytics/view/screens/analytics_screen.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/security/view/screens/lock_screen.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import '../../features/analytics/fake_analytics_repositories.dart';
import '../../features/budget/fake_budget_repositories.dart';
import '../../features/onboarding/fake_onboarding_repository.dart';
import '../../features/security/fake_security_repositories.dart';
import '../../features/transactions/fake_transaction_repositories.dart';

void main() {
  testWidgets('resolves the statistics route from the production graph', (
    tester,
  ) async {
    await configureDependencies(useInMemoryStorage: true);
    final appRouter = AppRouter();
    final router = appRouter.router;
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/statistics');
    await tester.pump();
    await tester.pump();

    expect(find.byType(AnalyticsScreen), findsOneWidget);
  });

  testWidgets('shows /statistics when the app lock is disabled', (
    tester,
  ) async {
    final securityHarness = SecurityTestHarness(
      initialState: SecurityState(
        appLockEnabled: false,
        pinConfigured: false,
        failedUnlockAttempts: 0,
        secureKeyReady: true,
        updatedAt: DateTime.utc(2026, 10, 15, 12),
      ),
    );
    final securityCubit = SecurityCubit(securityHarness.service);
    final onboardingCubit = OnboardingCubit(
      OnboardingService(FakeOnboardingRepository()),
    );
    final budgetCubit = BudgetCubit(BudgetTestHarness().service);
    final transactionsCubit = TransactionsCubit(
      TransactionsTestHarness().service,
    );
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
    router.go('/statistics');
    await tester.pump();
    await tester.pump();

    expect(find.byType(LockScreen), findsNothing);
    expect(find.byType(AnalyticsScreen), findsOneWidget);
  });

  testWidgets('opens statistics from the transactions screen', (tester) async {
    final securityHarness = SecurityTestHarness(
      initialState: SecurityState(
        appLockEnabled: false,
        pinConfigured: false,
        failedUnlockAttempts: 0,
        secureKeyReady: true,
        updatedAt: DateTime.utc(2026, 10, 15, 12),
      ),
    );
    final securityCubit = SecurityCubit(securityHarness.service);
    final onboardingCubit = OnboardingCubit(
      OnboardingService(FakeOnboardingRepository()),
    );
    final budgetCubit = BudgetCubit(BudgetTestHarness().service);
    final transactionsCubit = TransactionsCubit(
      TransactionsTestHarness().service,
    );
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

    await tester.tap(find.byTooltip('Statistics'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AnalyticsScreen), findsOneWidget);
  });

  testWidgets('protects /statistics behind the app lock', (tester) async {
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
    final budgetCubit = BudgetCubit(BudgetTestHarness().service);
    final transactionsCubit = TransactionsCubit(
      TransactionsTestHarness().service,
    );
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
    router.go('/statistics');
    await tester.pump();
    await tester.pump();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.byType(AnalyticsScreen), findsNothing);

    await tester.enterText(find.byType(Pinput), '123456');
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(LockScreen), findsNothing);
    expect(find.byType(AnalyticsScreen), findsOneWidget);
    expect(find.byType(SegmentedButton<AnalyticsPeriod>), findsOneWidget);
  });
}
