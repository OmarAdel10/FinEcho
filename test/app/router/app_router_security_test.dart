import 'package:finecho/app/router/app_router.dart';
import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:finecho/features/security/view/screens/lock_screen.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import '../../features/onboarding/fake_onboarding_repository.dart';
import '../../features/security/fake_security_repositories.dart';

void main() {
  testWidgets('protects a cold-loaded route until the PIN unlocks it', (
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
    final appRouter = AppRouter(
      onboardingCubit: onboardingCubit,
      securityCubit: securityCubit,
    );
    final router = appRouter.router;
    addTearDown(router.dispose);
    addTearDown(onboardingCubit.close);
    addTearDown(securityCubit.close);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/home');
    await tester.pump();
    await tester.pump();

    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    await tester.enterText(find.byType(Pinput), '123456');
    await tester.pump();

    expect(securityCubit.state.isLocked, isFalse);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Home')),
      findsOneWidget,
    );
    expect(
      securityHarness.securityRepository.state?.failedUnlockAttempts,
      isZero,
    );
  });
}
