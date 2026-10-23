import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/features/analytics/view_model/analytics_cubit.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/onboarding/data/models/onboarding_snapshot.dart';
import 'package:finecho/features/onboarding/data/models/onboarding_step.dart';
import 'package:finecho/features/onboarding/view/screens/onboarding_screen.dart';
import 'package:finecho/features/onboarding/view/screens/welcome_screen.dart';
import 'package:finecho/features/onboarding/view_model/models/onboarding_state.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import '../analytics/fake_analytics_repositories.dart';
import '../budget/fake_budget_repositories.dart';
import '../security/fake_security_repositories.dart';
import '../transactions/fake_transaction_repositories.dart';
import 'fake_onboarding_repository.dart';

void main() {
  late FakeOnboardingRepository repository;
  late OnboardingCubit cubit;

  setUp(() {
    repository = FakeOnboardingRepository();
    cubit = OnboardingCubit(OnboardingService(repository));
  });

  tearDown(() async {
    await cubit.close();
  });

  Widget wrapScreen(Widget screen) {
    return MaterialApp(
      home: BlocProvider<OnboardingCubit>.value(value: cubit, child: screen),
    );
  }

  group('onboarding screens', () {
    testWidgets('renders the welcome CTA', (tester) async {
      await tester.pumpWidget(wrapScreen(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to FinEcho'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('advances from privacy to voice logging', (tester) async {
      await cubit.load();
      await tester.pumpWidget(wrapScreen(const OnboardingScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(cubit.state.currentStep, OnboardingStep.voiceLogging);
      expect(find.text('Onboarding 2/3'), findsOneWidget);
    });

    testWidgets('saves security setup after a valid PIN', (tester) async {
      // Close the setUp cubit before replacing it so it does not leak.
      await cubit.close();
      repository = FakeOnboardingRepository(
        initialSnapshot: const OnboardingSnapshot(
          currentStep: OnboardingStep.securitySetup,
          isCompleted: false,
          biometricsEnabled: false,
          smsAutomationEnabled: false,
        ),
      );
      cubit = OnboardingCubit(OnboardingService(repository));
      await cubit.load();
      final securityHarness = SecurityTestHarness();
      final securityCubit = SecurityCubit(securityHarness.service);
      final transactionsHarness = TransactionsTestHarness();
      final transactionsCubit = TransactionsCubit(transactionsHarness.service);
      final budgetHarness = BudgetTestHarness();
      final budgetCubit = BudgetCubit(budgetHarness.service);
      final analyticsCubit = AnalyticsCubit(AnalyticsTestHarness().service);
      final appRouter = AppRouter(
        onboardingCubit: cubit,
        securityCubit: securityCubit,
        transactionsCubit: transactionsCubit,
        budgetCubit: budgetCubit,
        analyticsCubit: analyticsCubit,
      );
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      await tester.pump();
      appRouter.router.go('/security-setup');
      await tester.pump();

      await tester.enterText(find.byType(Pinput), '123456');
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Finish setup'));
      await tester.pump();
      await tester.pump();

      expect(cubit.state.status, OnboardingStatus.completed);
      expect(repository.saved.last.isCompleted, isTrue);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('FinEcho'),
        ),
        findsOneWidget,
      );
      expect(securityHarness.securityRepository.state?.appLockEnabled, isTrue);
      expect(securityHarness.securityRepository.state?.pinConfigured, isTrue);
      appRouter.router.dispose();
      await securityCubit.close();
      await transactionsCubit.close();
      await budgetCubit.close();
      await analyticsCubit.close();
    });

    testWidgets('reaches the security setup step and finishes onboarding', (
      tester,
    ) async {
      await cubit.load();
      await cubit.nextStep();
      await cubit.nextStep();
      final securityHarness = SecurityTestHarness();
      final securityCubit = SecurityCubit(securityHarness.service);
      final transactionsCubit = TransactionsCubit(
        TransactionsTestHarness().service,
      );
      final budgetCubit = BudgetCubit(BudgetTestHarness().service);
      final analyticsCubit = AnalyticsCubit(AnalyticsTestHarness().service);
      final appRouter = AppRouter(
        onboardingCubit: cubit,
        securityCubit: securityCubit,
        transactionsCubit: transactionsCubit,
        budgetCubit: budgetCubit,
        analyticsCubit: analyticsCubit,
      );
      addTearDown(appRouter.router.dispose);
      addTearDown(securityCubit.close);
      addTearDown(transactionsCubit.close);
      addTearDown(budgetCubit.close);
      addTearDown(analyticsCubit.close);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      await tester.pump();
      appRouter.router.go('/onboarding');
      await tester.pump();
      await tester.pump();

      expect(find.text('Set up security'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump();

      expect(cubit.state.smsAutomationEnabled, isTrue);
      await tester.tap(find.text('Set up security'));
      await tester.pump();
      await tester.pump();

      expect(cubit.state.currentStep, OnboardingStep.securitySetup);
      expect(find.text('Security setup'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump();

      expect(cubit.state.biometricsEnabled, isTrue);
      await tester.enterText(find.byType(Pinput), '123456');
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Finish setup'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(cubit.state.status, OnboardingStatus.completed);
      expect(repository.saved.last.isCompleted, isTrue);
      expect(repository.saved.last.biometricsEnabled, isTrue);
      expect(repository.saved.last.smsAutomationEnabled, isTrue);
      expect(securityHarness.securityRepository.state?.pinConfigured, isTrue);
    });

    testWidgets('goes back to the previous step', (tester) async {
      await cubit.load();
      await cubit.nextStep();
      await tester.pumpWidget(wrapScreen(const OnboardingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(cubit.state.currentStep, OnboardingStep.privacy);
    });

    testWidgets('stores the SMS automation preference', (tester) async {
      await cubit.load();
      await cubit.nextStep();
      await cubit.nextStep();
      await tester.pumpWidget(wrapScreen(const OnboardingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Enable SMS automation'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(cubit.state.smsAutomationEnabled, isTrue);
    });

    testWidgets('stores the biometric preference on the setup screen', (
      tester,
    ) async {
      await cubit.load();
      final securityHarness = SecurityTestHarness();
      final securityCubit = SecurityCubit(securityHarness.service);
      final transactionsCubit = TransactionsCubit(
        TransactionsTestHarness().service,
      );
      final budgetCubit = BudgetCubit(BudgetTestHarness().service);
      final analyticsCubit = AnalyticsCubit(AnalyticsTestHarness().service);
      final appRouter = AppRouter(
        onboardingCubit: cubit,
        securityCubit: securityCubit,
        transactionsCubit: transactionsCubit,
        budgetCubit: budgetCubit,
        analyticsCubit: analyticsCubit,
      );
      addTearDown(appRouter.router.dispose);
      addTearDown(securityCubit.close);
      addTearDown(transactionsCubit.close);
      addTearDown(budgetCubit.close);
      addTearDown(analyticsCubit.close);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      await tester.pump();
      appRouter.router.go('/security-setup');
      await tester.pump();
      await tester.pump();

      expect(find.text('Use device biometrics'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump();

      expect(cubit.state.biometricsEnabled, isTrue);
    });

    testWidgets('shows the onboarding error on the setup screen', (
      tester,
    ) async {
      await cubit.load();
      final securityHarness = SecurityTestHarness();
      final securityCubit = SecurityCubit(securityHarness.service);
      final transactionsCubit = TransactionsCubit(
        TransactionsTestHarness().service,
      );
      final budgetCubit = BudgetCubit(BudgetTestHarness().service);
      final analyticsCubit = AnalyticsCubit(AnalyticsTestHarness().service);
      final appRouter = AppRouter(
        onboardingCubit: cubit,
        securityCubit: securityCubit,
        transactionsCubit: transactionsCubit,
        budgetCubit: budgetCubit,
        analyticsCubit: analyticsCubit,
      );
      addTearDown(appRouter.router.dispose);
      addTearDown(securityCubit.close);
      addTearDown(transactionsCubit.close);
      addTearDown(budgetCubit.close);
      addTearDown(analyticsCubit.close);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      await tester.pump();
      appRouter.router.go('/security-setup');
      await tester.pump();
      await tester.pump();

      await cubit.complete();
      await tester.pump();

      expect(find.text('Enter a six-digit PIN.'), findsOneWidget);
    });

    testWidgets('warns when the setup cannot be completed', (tester) async {
      // Close the setUp cubit before replacing it so it does not leak.
      await cubit.close();
      repository = FakeOnboardingRepository(
        initialSnapshot: const OnboardingSnapshot(
          currentStep: OnboardingStep.securitySetup,
          isCompleted: false,
          biometricsEnabled: false,
          smsAutomationEnabled: false,
        ),
      );
      cubit = OnboardingCubit(OnboardingService(repository));
      await cubit.load();
      final securityHarness = SecurityTestHarness();
      final securityCubit = SecurityCubit(securityHarness.service);
      final transactionsCubit = TransactionsCubit(
        TransactionsTestHarness().service,
      );
      final budgetCubit = BudgetCubit(BudgetTestHarness().service);
      final analyticsCubit = AnalyticsCubit(AnalyticsTestHarness().service);
      final appRouter = AppRouter(
        onboardingCubit: cubit,
        securityCubit: securityCubit,
        transactionsCubit: transactionsCubit,
        budgetCubit: budgetCubit,
        analyticsCubit: analyticsCubit,
      );
      addTearDown(appRouter.router.dispose);
      addTearDown(securityCubit.close);
      addTearDown(transactionsCubit.close);
      addTearDown(budgetCubit.close);
      addTearDown(analyticsCubit.close);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      await tester.pump();
      appRouter.router.go('/security-setup');
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(Pinput), '123456');
      await tester.pump();
      repository.saveError = Exception('save failed');
      await tester.tap(find.text('Finish setup'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(cubit.state.status, OnboardingStatus.failure);
      expect(
        cubit.state.errorMessage,
        contains('Could not save the onboarding preferences'),
      );
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Could not save the onboarding preferences.'),
        findsOneWidget,
      );
      expect(securityHarness.securityRepository.state?.pinConfigured, isTrue);
    });

    testWidgets('shows the security failure on the setup screen', (
      tester,
    ) async {
      await cubit.load();
      final securityHarness = SecurityTestHarness();
      securityHarness.credentialRepository.saveError = Exception('keystore');
      final securityCubit = SecurityCubit(securityHarness.service);
      final transactionsCubit = TransactionsCubit(
        TransactionsTestHarness().service,
      );
      final budgetCubit = BudgetCubit(BudgetTestHarness().service);
      final analyticsCubit = AnalyticsCubit(AnalyticsTestHarness().service);
      final appRouter = AppRouter(
        onboardingCubit: cubit,
        securityCubit: securityCubit,
        transactionsCubit: transactionsCubit,
        budgetCubit: budgetCubit,
        analyticsCubit: analyticsCubit,
      );
      addTearDown(appRouter.router.dispose);
      addTearDown(securityCubit.close);
      addTearDown(transactionsCubit.close);
      addTearDown(budgetCubit.close);
      addTearDown(analyticsCubit.close);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: appRouter.router),
      );
      await tester.pump();
      appRouter.router.go('/security-setup');
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(Pinput), '123456');
      await tester.pump();
      await tester.tap(find.text('Finish setup'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Could not save app lock. Please try again.'),
        findsOneWidget,
      );
    });
  });
}
