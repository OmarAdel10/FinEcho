import 'dart:async';

import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/view/screens/lock_screen.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

import 'fake_security_repositories.dart';

void main() {
  Future<SecurityCubit> createCubit(
    SecurityTestHarness harness, {
    FakeBiometricAuthenticator? biometrics,
  }) async {
    await harness.credentialRepository.savePin('123456');
    final cubit = SecurityCubit(harness.service, biometrics: biometrics);
    await cubit.load();
    return cubit;
  }

  Widget wrapScreen(SecurityCubit cubit, TextEditingController pinController) {
    return MaterialApp(
      home: BlocProvider<SecurityCubit>.value(
        value: cubit,
        child: LockScreen(pinController: pinController),
      ),
    );
  }

  group('LockScreen', () {
    testWidgets('reports a wrong PIN and keeps the lock message', (
      tester,
    ) async {
      final harness = SecurityTestHarness(
        initialState: SecurityState(
          appLockEnabled: true,
          pinConfigured: true,
          failedUnlockAttempts: 0,
          secureKeyReady: true,
          updatedAt: DateTime.utc(2026, 10, 15, 12),
        ),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final pinController = TextEditingController();
      addTearDown(pinController.dispose);
      final cubit = await createCubit(harness);
      await tester.pumpWidget(wrapScreen(cubit, pinController));
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(Pinput), '000000');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cubit.state.status, SecurityAccessStatus.failure);
      expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
      expect(harness.securityRepository.state?.failedUnlockAttempts, 1);
      expect(pinController.text, isEmpty);
      await cubit.close();
    });

    testWidgets('unlocks with the configured PIN', (tester) async {
      final harness = SecurityTestHarness(
        initialState: SecurityState(
          appLockEnabled: true,
          pinConfigured: true,
          failedUnlockAttempts: 0,
          secureKeyReady: true,
          updatedAt: DateTime.utc(2026, 10, 15, 12),
        ),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final pinController = TextEditingController();
      addTearDown(pinController.dispose);
      final cubit = await createCubit(harness);
      await tester.pumpWidget(wrapScreen(cubit, pinController));
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(Pinput), '123456');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cubit.state.status, SecurityAccessStatus.unlocked);
      expect(find.text('Incorrect PIN. Try again.'), findsNothing);
      expect(harness.securityRepository.state?.failedUnlockAttempts, isZero);
      await cubit.close();
    });

    testWidgets('rejects a short PIN submitted from the unlock button', (
      tester,
    ) async {
      final harness = SecurityTestHarness(
        initialState: SecurityState(
          appLockEnabled: true,
          pinConfigured: true,
          failedUnlockAttempts: 0,
          secureKeyReady: true,
          updatedAt: DateTime.utc(2026, 10, 15, 12),
        ),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final pinController = TextEditingController();
      addTearDown(pinController.dispose);
      final cubit = await createCubit(harness);
      await tester.pumpWidget(wrapScreen(cubit, pinController));
      await tester.pump();
      await tester.pump();

      await tester.enterText(find.byType(Pinput), '12345');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await tester.pump();

      expect(cubit.state.status, SecurityAccessStatus.failure);
      expect(find.text('Enter a six-digit PIN.'), findsOneWidget);
      expect(harness.credentialRepository.verifiedPins, isEmpty);
      await cubit.close();
    });

    testWidgets('clears the entered PIN when the app relocks mid-verify', (
      tester,
    ) async {
      final harness = SecurityTestHarness(
        initialState: SecurityState(
          appLockEnabled: true,
          pinConfigured: true,
          failedUnlockAttempts: 0,
          secureKeyReady: true,
          updatedAt: DateTime.utc(2026, 10, 15, 12),
        ),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final pinController = TextEditingController();
      addTearDown(pinController.dispose);
      final cubit = await createCubit(harness);
      final gate = Completer<void>();
      harness.credentialRepository.verifyGate = gate;
      await tester.pumpWidget(wrapScreen(cubit, pinController));
      await tester.pump();

      await tester.enterText(find.byType(Pinput), '123456');
      await tester.pump();
      expect(cubit.state.status, SecurityAccessStatus.submitting);

      cubit.lock();
      await tester.pump();

      expect(cubit.state.status, SecurityAccessStatus.ready);
      expect(pinController.text, isEmpty);

      gate.complete();
      await tester.pump();
      expect(cubit.state.status, SecurityAccessStatus.ready);
      await cubit.close();
    });

    testWidgets('auto-prompts and unlocks with the device biometric', (
      tester,
    ) async {
      final biometrics = FakeBiometricAuthenticator()..available = true;
      final harness = SecurityTestHarness(
        initialState: SecurityState(
          appLockEnabled: true,
          pinConfigured: true,
          failedUnlockAttempts: 0,
          secureKeyReady: true,
          biometricsEnabled: true,
          updatedAt: DateTime.utc(2026, 10, 15, 12),
        ),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final pinController = TextEditingController();
      addTearDown(pinController.dispose);
      final cubit = await createCubit(harness, biometrics: biometrics);

      await tester.pumpWidget(wrapScreen(cubit, pinController));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The lock screen auto-prompts once, and the successful prompt
      // unlocks the app and removes the lock UI.
      expect(biometrics.authenticateCalls, 1);
      expect(cubit.state.status, SecurityAccessStatus.unlocked);
      await cubit.close();
    });

    testWidgets('keeps the PIN-only screen when biometrics are off', (
      tester,
    ) async {
      final biometrics = FakeBiometricAuthenticator()..available = true;
      final harness = SecurityTestHarness(
        initialState: SecurityState(
          appLockEnabled: true,
          pinConfigured: true,
          failedUnlockAttempts: 0,
          secureKeyReady: true,
          updatedAt: DateTime.utc(2026, 10, 15, 12),
        ),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final pinController = TextEditingController();
      addTearDown(pinController.dispose);
      final cubit = await createCubit(harness, biometrics: biometrics);

      await tester.pumpWidget(wrapScreen(cubit, pinController));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Use biometrics'), findsNothing);
      expect(biometrics.authenticateCalls, isZero);
      expect(cubit.state.status, SecurityAccessStatus.ready);
      await cubit.close();
    });

    testWidgets('keeps the lock when the biometric prompt is cancelled', (
      tester,
    ) async {
      final biometrics = FakeBiometricAuthenticator()
        ..available = true
        ..authenticateResult = false;
      final harness = SecurityTestHarness(
        initialState: SecurityState(
          appLockEnabled: true,
          pinConfigured: true,
          failedUnlockAttempts: 0,
          secureKeyReady: true,
          biometricsEnabled: true,
          updatedAt: DateTime.utc(2026, 10, 15, 12),
        ),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final pinController = TextEditingController();
      addTearDown(pinController.dispose);
      final cubit = await createCubit(harness, biometrics: biometrics);

      await tester.pumpWidget(wrapScreen(cubit, pinController));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cubit.state.status, SecurityAccessStatus.failure);
      expect(cubit.state.isLocked, isTrue);
      expect(
        find.text('Biometric unlock was cancelled. Enter your PIN.'),
        findsOneWidget,
      );
      // The retry button stays available next to the PIN fallback.
      expect(find.text('Use biometrics'), findsOneWidget);
      expect(biometrics.authenticateCalls, 1);
      await cubit.close();
    });
  });
}
