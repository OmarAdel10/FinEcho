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

    test('rejects a wrong PIN and persists the failed attempt', () async {
      final harness = SecurityTestHarness(
        initialState: _configuredState(),
        now: () => DateTime.utc(2026, 10, 15, 12),
      );
      final cubit = SecurityCubit(harness.service);

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

      final unlocked = await cubit.unlockWithPin('123456');

      expect(unlocked, isTrue);
      expect(cubit.state.status, SecurityAccessStatus.unlocked);
      expect(cubit.state.errorMessage, isNull);
      expect(harness.securityRepository.state?.failedUnlockAttempts, isZero);
      expect(harness.securityRepository.state?.lockedUntil, isNull);
      expect(harness.securityRepository.state?.updatedAt, now);
      await cubit.close();
    });

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
  });
}
