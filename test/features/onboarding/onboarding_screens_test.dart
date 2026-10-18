import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/features/onboarding/data/models/onboarding_snapshot.dart';
import 'package:finecho/features/onboarding/data/models/onboarding_step.dart';
import 'package:finecho/features/onboarding/view/screens/onboarding_screen.dart';
import 'package:finecho/features/onboarding/view/screens/welcome_screen.dart';
import 'package:finecho/features/onboarding/view_model/models/onboarding_state.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

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
      final appRouter = AppRouter(
        onboardingCubit: cubit,
        securityCubit: securityCubit,
        transactionsCubit: transactionsCubit,
        budgetCubit: budgetCubit,
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
    });
  });
}
