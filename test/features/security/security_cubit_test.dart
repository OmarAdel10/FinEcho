import 'dart:async';

import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:finecho/features/security/view_model/services/security_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_security_repositories.dart';

SecurityState _configuredState({
  int failedAttempts = 0,
  DateTime? lockedUntil,
}) {
  return SecurityState(
    appLockEnabled: true,
    pinConfigured: true,
    failedUnlockAttempts: failedAttempts,
    lockedUntil: lockedUntil,
    secureKeyReady: true,
    updatedAt: DateTime.utc(2026, 10, 15, 12),
  );
}

void main() {
  group('SecurityCubit', () {
    test('loads a safe default when no state is persisted', () async {
      final harness = SecurityTestHarness(
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final cubit = SecurityCubit(harness.service);

      await cubit.load();

      expect(cubit.state.status, SecurityAccessStatus.unlocked);
      expect(cubit.state.isLocked, isFalse);
      expect(cubit.state.securityState.appLockEnabled, isFalse);
      expect(cubit.state.securityState.pinConfigured, isFalse);
      expect(cubit.state.securityState.failedUnlockAttempts, isZero);
      expect(
        cubit.state.securityState.updatedAt,
        DateTime.utc(2026, 10, 15, 12),
      );
      expect(harness.securityRepository.state, isNull);
      await cubit.close();
    });

    test('fails closed when a verifier exists without metadata', () async {
      final harness = SecurityTestHarness(
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      await harness.credentialRepository.savePin('123456');
      final cubit = SecurityCubit(harness.service);

      await cubit.load();

      expect(cubit.state.status, SecurityAccessStatus.ready);
      expect(cubit.state.isLocked, isTrue);
      expect(cubit.state.securityState.appLockEnabled, isTrue);
      expect(cubit.state.securityState.pinConfigured, isTrue);
      expect(await harness.service.verifyPin('123456'), isTrue);
      await cubit.close();
    });

    test('reports a load failure and retries successfully', () async {
      final harness = SecurityTestHarness(
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      harness.securityRepository.getError = const FormatException('corrupt');
      final cubit = SecurityCubit(harness.service);

      await cubit.load();
      expect(cubit.state.status, SecurityAccessStatus.error);
      expect(cubit.state.hasLoadError, isTrue);
      expect(
        cubit.state.errorMessage,
        'Could not load security settings. Please try again.',
      );

      harness.securityRepository.getError = null;
      await cubit.load();

      expect(cubit.state.status, SecurityAccessStatus.unlocked);
      await cubit.close();
    });

    test('resets app lock after a load failure', () async {
      final harness = SecurityTestHarness(
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      await harness.credentialRepository.savePin('123456');
      harness.securityRepository.getError = const FormatException('corrupt');
      final cubit = SecurityCubit(harness.service);
      await cubit.load();
      expect(cubit.state.status, SecurityAccessStatus.error);

      harness.securityRepository.getError = null;
      final reset = await cubit.resetLock();

      expect(reset, isTrue);
      expect(cubit.state.status, SecurityAccessStatus.unlocked);
      expect(await harness.credentialRepository.hasPin(), isFalse);
      await cubit.close();
    });

    test('loads configured security in its locked ready state', () async {
      final persistedState = _configuredState();
      final harness = SecurityTestHarness(
        initialState: persistedState,
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final cubit = SecurityCubit(harness.service);

      await cubit.load();

      expect(cubit.state.status, SecurityAccessStatus.ready);
      expect(cubit.state.securityState, persistedState);
      expect(cubit.state.isLocked, isTrue);
      await cubit.close();
    });

    test('configures a valid six-digit PIN', () async {
      final now = DateTime.utc(2026, 10, 15, 12);
      final harness = SecurityTestHarness(now: () => now);
      final cubit = SecurityCubit(harness.service);

      await cubit.load();
      final configured = await cubit.configure('123456');

      expect(configured, isTrue);
      expect(cubit.state.status, SecurityAccessStatus.unlocked);
      expect(harness.credentialRepository.hasPin(), completion(isTrue));
      expect(harness.securityRepository.state?.appLockEnabled, isTrue);
      expect(harness.securityRepository.state?.pinConfigured, isTrue);
      expect(harness.securityRepository.state?.failedUnlockAttempts, isZero);
      expect(harness.securityRepository.state?.lockedUntil, isNull);
      expect(harness.securityRepository.state?.updatedAt, now);
      await cubit.close();
    });

    test('rejects a PIN that is not six digits', () async {
      final harness = SecurityTestHarness(
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final cubit = SecurityCubit(harness.service);

      await cubit.load();
      final configured = await cubit.configure('12345');

      expect(configured, isFalse);
      expect(cubit.state.status, SecurityAccessStatus.failure);
      expect(cubit.state.errorMessage, 'Enter a six-digit PIN.');
      expect(harness.credentialRepository.hasPin(), completion(isFalse));
      expect(harness.securityRepository.updates, isEmpty);
      await cubit.close();
    });

    test('refuses to overwrite an existing PIN verifier', () async {
      final harness = SecurityTestHarness(
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      await harness.credentialRepository.savePin('123456');
      final cubit = SecurityCubit(harness.service);
      await cubit.load();

      final configured = await cubit.configure('654321');

      expect(configured, isFalse);
      expect(cubit.state.status, SecurityAccessStatus.failure);
      expect(cubit.state.errorMessage, 'App lock is already configured.');
      expect(await harness.service.verifyPin('123456'), isTrue);
      expect(await harness.service.verifyPin('654321'), isFalse);
      await cubit.close();
    });

    test(
      'rolls back the verifier when configured state cannot be saved',
      () async {
        final harness = SecurityTestHarness(
          now: () => DateTime.utc(2026, 10, 15, 12),
        );
        final cubit = SecurityCubit(harness.service);
        await cubit.load();
        harness.securityRepository.updateError = Exception('disk full');

        final configured = await cubit.configure('123456');

        expect(configured, isFalse);
        expect(cubit.state.status, SecurityAccessStatus.failure);
        expect(
          cubit.state.errorMessage,
          'Could not save app lock. Please try again.',
        );
        expect(await harness.credentialRepository.hasPin(), isFalse);
        expect(harness.securityRepository.updates, isEmpty);
        await cubit.close();
      },
    );

    test('rejects a wrong PIN and persists the failed attempt', () async {
      final harness = SecurityTestHarness(
        initialState: _configuredState(),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final cubit = SecurityCubit(harness.service);
      await cubit.load();

      final unlocked = await cubit.unlockWithPin('000000');

      expect(unlocked, isFalse);
      expect(cubit.state.status, SecurityAccessStatus.failure);
      expect(cubit.state.errorMessage, 'Incorrect PIN. Try again.');
      expect(harness.credentialRepository.verifiedPins, <String>['000000']);
      expect(harness.securityRepository.state?.failedUnlockAttempts, 1);
      expect(harness.securityRepository.state?.lockedUntil, isNull);
      expect(harness.securityRepository.updates, hasLength(1));
      await cubit.close();
    });

    test('clears failed attempts after a successful unlock', () async {
      final now = DateTime.utc(2026, 10, 15, 12, 30);
      final harness = SecurityTestHarness(
        initialState: _configuredState(failedAttempts: 2),
        now: () => now,
      );
      await harness.credentialRepository.savePin('123456');
      final cubit = SecurityCubit(harness.service);
      await cubit.load();

      final unlocked = await cubit.unlockWithPin('123456');

      expect(unlocked, isTrue);
      expect(cubit.state.status, SecurityAccessStatus.unlocked);
      expect(cubit.state.errorMessage, isNull);
      expect(harness.securityRepository.state?.failedUnlockAttempts, isZero);
      expect(harness.securityRepository.state?.lockedUntil, isNull);
      expect(harness.securityRepository.state?.updatedAt, now);
      await cubit.close();
    });

    test('relocks an unlocked app without changing persisted state', () async {
      final harness = SecurityTestHarness(
        initialState: _configuredState(),
        now: () => DateTime.utc(2026, 10, 15, 12, 30),
      );
      await harness.credentialRepository.savePin('123456');
      final cubit = SecurityCubit(harness.service);
      await cubit.load();
      await cubit.unlockWithPin('123456');
      final unlockedState = cubit.state.securityState;

      cubit.lock();

      expect(cubit.state.status, SecurityAccessStatus.ready);
      expect(cubit.state.isLocked, isTrue);
      expect(cubit.state.securityState, unlockedState);
      expect(harness.securityRepository.updates, hasLength(1));
      await cubit.close();
    });

    test('does not lock when the app lock is disabled', () async {
      final harness = SecurityTestHarness(
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final cubit = SecurityCubit(harness.service);
      await cubit.load();

      cubit.lock();

      expect(cubit.state.status, SecurityAccessStatus.unlocked);
      expect(cubit.state.isLocked, isFalse);
      await cubit.close();
    });

    test('stays locked when the app pauses during PIN verification', () async {
      final harness = SecurityTestHarness(
        initialState: _configuredState(),
        now: () => DateTime.utc(2026, 10, 15, 12, 30),
      );
      await harness.credentialRepository.savePin('123456');
      final cubit = SecurityCubit(harness.service);
      await cubit.load();
      final gate = Completer<void>();
      harness.credentialRepository.verifyGate = gate;

      final unlock = cubit.unlockWithPin('123456');
      cubit.lock();
      gate.complete();

      expect(await unlock, isFalse);
      expect(cubit.state.status, SecurityAccessStatus.ready);
      expect(cubit.state.isLocked, isTrue);
      await cubit.close();
    });

    test('rejects a malformed PIN before verification', () async {
      final harness = SecurityTestHarness(
        initialState: _configuredState(),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      await harness.credentialRepository.savePin('123456');
      final cubit = SecurityCubit(harness.service);
      await cubit.load();

      final unlocked = await cubit.unlockWithPin('123');

      expect(unlocked, isFalse);
      expect(cubit.state.errorMessage, 'Enter a six-digit PIN.');
      expect(harness.credentialRepository.verifiedPins, isEmpty);
      await cubit.close();
    });

    test('ignores a second unlock while one is verifying', () async {
      final harness = SecurityTestHarness(
        initialState: _configuredState(),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      await harness.credentialRepository.savePin('123456');
      final cubit = SecurityCubit(harness.service);
      await cubit.load();
      final gate = Completer<void>();
      harness.credentialRepository.verifyGate = gate;

      final first = cubit.unlockWithPin('123456');
      final second = await cubit.unlockWithPin('123456');
      gate.complete();

      expect(second, isFalse);
      expect(await first, isTrue);
      expect(harness.credentialRepository.verifiedPins, hasLength(1));
      await cubit.close();
    });

    test(
      'reports a verification failure without recording an attempt',
      () async {
        final harness = SecurityTestHarness(
          initialState: _configuredState(),
          now: () => DateTime.utc(2026, 10, 15, 12),
        );
        await harness.credentialRepository.savePin('123456');
        final cubit = SecurityCubit(harness.service);
        await cubit.load();
        harness.credentialRepository.verifyError = Exception('keystore');

        final unlocked = await cubit.unlockWithPin('123456');

        expect(unlocked, isFalse);
        expect(cubit.state.status, SecurityAccessStatus.failure);
        expect(
          cubit.state.errorMessage,
          'Could not verify PIN. Please try again.',
        );
        expect(harness.securityRepository.updates, isEmpty);
        await cubit.close();
      },
    );

    test('locks out after five failures and stops further attempts', () async {
      final now = DateTime.now().toUtc().add(const Duration(hours: 1));
      final harness = SecurityTestHarness(
        initialState: _configuredState(),
        now: () => now,
      );
      await harness.credentialRepository.savePin('123456');
      final cubit = SecurityCubit(harness.service);
      await cubit.load();

      for (var attempt = 0; attempt < 5; attempt++) {
        final unlocked = await cubit.unlockWithPin('000000');
        expect(unlocked, isFalse);
      }

      expect(
        cubit.state.securityState.failedUnlockAttempts,
        SecurityService.maxFailedAttemptsBeforeLockout,
      );
      expect(
        cubit.state.securityState.lockedUntil,
        now.add(SecurityService.lockoutDuration),
      );
      expect(cubit.state.errorMessage, 'Too many attempts. Try again later.');
      expect(cubit.state.isLockedOut, isTrue);

      final lockedOutAttempt = await cubit.unlockWithPin('000000');

      expect(lockedOutAttempt, isFalse);
      expect(harness.securityRepository.updates, hasLength(5));
      expect(harness.credentialRepository.verifiedPins, hasLength(5));
      await cubit.close();
    });

    test('ignores a load after close', () async {
      final harness = SecurityTestHarness(
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final cubit = SecurityCubit(harness.service);
      await cubit.close();

      await cubit.load();

      expect(cubit.state.status, SecurityAccessStatus.loading);
      expect(harness.securityRepository.updates, isEmpty);
    });
  });
}
