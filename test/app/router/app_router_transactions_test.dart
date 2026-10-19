import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/core/models/account.dart';
import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/core/models/transaction.dart';
import 'package:finecho/features/budget/view_model/budget_cubit.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/security/view/screens/lock_screen.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/transactions/view/screens/transactions_screen.dart';
import 'package:finecho/features/transactions/view_model/transactions_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import '../../features/budget/fake_budget_repositories.dart';
import '../../features/onboarding/fake_onboarding_repository.dart';
import '../../features/security/fake_security_repositories.dart';
import '../../features/transactions/fake_transaction_repositories.dart';

void main() {
  testWidgets('renders the transactions screen behind the app lock', (
    tester,
  ) async {
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
    final transactionsHarness = TransactionsTestHarness();
    await transactionsHarness.accountRepository.create(
      const Account(
        id: 'account-1',
        name: 'Cash',
        type: AccountType.cash,
        currency: 'EGP',
        balanceMinorUnits: 50000,
      ),
    );
    await transactionsHarness.transactionRepository.create(
      Transaction(
        id: 'txn-1',
        accountId: 'account-1',
        amountMinorUnits: 1250,
        timestamp: now,
        type: TransactionType.expense,
        source: TransactionSource.manual,
      ),
    );
    final transactionsCubit = TransactionsCubit(transactionsHarness.service);
    await transactionsCubit.load();
    final budgetHarness = BudgetTestHarness();
    final budgetCubit = BudgetCubit(budgetHarness.service);
    final appRouter = AppRouter(
      onboardingCubit: onboardingCubit,
      securityCubit: securityCubit,
      transactionsCubit: transactionsCubit,
      budgetCubit: budgetCubit,
    );
    final router = appRouter.router;
    addTearDown(router.dispose);
    addTearDown(onboardingCubit.close);
    addTearDown(securityCubit.close);
    addTearDown(transactionsCubit.close);
    addTearDown(budgetCubit.close);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/home');
    await tester.pump();
    await tester.pump();

    expect(find.byType(LockScreen), findsOneWidget);

    await tester.enterText(find.byType(Pinput), '123456');
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(TransactionsScreen), findsOneWidget);
    expect(find.text('FinEcho'), findsOneWidget);
    expect(find.text('-12.50'), findsOneWidget);
  });
}
