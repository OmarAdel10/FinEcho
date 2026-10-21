import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/view_model/services/security_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_security_repositories.dart';

void main() {
  final now = DateTime.utc(2026, 10, 21, 9);

  SecurityState configuredState() {
    return SecurityState(
      appLockEnabled: true,
      pinConfigured: true,
      failedUnlockAttempts: 0,
      secureKeyReady: true,
      updatedAt: now,
    );
  }

  SecurityState disabledState() {
    return SecurityState(
      appLockEnabled: false,
      pinConfigured: false,
      failedUnlockAttempts: 0,
      secureKeyReady: false,
      updatedAt: now,
    );
  }

  group('SecurityService.load', () {
    test('returns a disabled state when nothing is stored', () async {
      final harness = SecurityTestHarness(now: () => now);

      final state = await harness.service.load();

      expect(state.appLockEnabled, isFalse);
      expect(state.pinConfigured, isFalse);
      expect(harness.securityRepository.updates, isEmpty);
    });

    test('repairs missing metadata when a verifier exists', () async {
      final harness = SecurityTestHarness(now: () => now);
      await harness.credentialRepository.savePin('123456');

      final state = await harness.service.load();

      expect(state.appLockEnabled, isTrue);
      expect(state.pinConfigured, isTrue);
      expect(harness.securityRepository.state?.appLockEnabled, isTrue);
      expect(harness.securityRepository.state?.pinConfigured, isTrue);
    });

    test('keeps a configured state when the verifier is readable', () async {
      final harness = SecurityTestHarness(
        initialState: configuredState(),
        now: () => now,
      );
      await harness.credentialRepository.savePin('123456');

      final state = await harness.service.load();

      expect(state, harness.securityRepository.state);
      expect(harness.securityRepository.updates, isEmpty);
    });

    test('fails closed when a configured lock has no verifier', () async {
      final harness = SecurityTestHarness(
        initialState: configuredState(),
        now: () => now,
      );

      await expectLater(harness.service.load(), throwsStateError);
    });

    test('fails closed when the stored verifier payload is corrupt', () async {
      final harness = SecurityTestHarness(
        initialState: configuredState(),
        now: () => now,
      );
      harness.credentialRepository.hasPinError = const FormatException(
        'Invalid persisted PIN verifier.',
      );

      await expectLater(harness.service.load(), throwsFormatException);
    });

    test('fails closed when the stored metadata is incomplete', () async {
      final harness = SecurityTestHarness(
        initialState: disabledState().copyWith(appLockEnabled: true),
        now: () => now,
      );

      await expectLater(harness.service.load(), throwsStateError);
    });

    test('keeps a disabled state when no verifier exists', () async {
      final harness = SecurityTestHarness(
        initialState: disabledState(),
        now: () => now,
      );

      final state = await harness.service.load();

      expect(state.appLockEnabled, isFalse);
      expect(harness.securityRepository.updates, isEmpty);
    });

    test(
      'keeps the lock when the repaired metadata cannot be stored',
      () async {
        final harness = SecurityTestHarness(now: () => now);
        await harness.credentialRepository.savePin('123456');
        harness.securityRepository.updateError = Exception('keystore write');

        final state = await harness.service.load();

        expect(state.appLockEnabled, isTrue);
        expect(state.pinConfigured, isTrue);
        expect(harness.securityRepository.state, isNull);
      },
    );
  });

  group('SecurityService.reset', () {
    test('clears the verifier and the lock metadata', () async {
      final harness = SecurityTestHarness(
        initialState: configuredState(),
        now: () => now,
      );
      await harness.credentialRepository.savePin('123456');

      final cleared = await harness.service.reset();

      expect(cleared, isTrue);
      expect(await harness.credentialRepository.hasPin(), isFalse);
      expect(harness.securityRepository.state?.appLockEnabled, isFalse);
      expect(harness.securityRepository.state?.pinConfigured, isFalse);
    });

    test('clears the metadata when the verifier cannot be erased', () async {
      final harness = SecurityTestHarness(
        initialState: configuredState(),
        now: () => now,
      );
      await harness.credentialRepository.savePin('123456');
      harness.credentialRepository.clearError = Exception('keystore delete');

      final cleared = await harness.service.reset();

      expect(cleared, isFalse);
      expect(harness.securityRepository.state?.appLockEnabled, isFalse);
      expect(harness.securityRepository.state?.pinConfigured, isFalse);
    });

    test('clears the verifier when the metadata cannot be written', () async {
      final harness = SecurityTestHarness(
        initialState: configuredState(),
        now: () => now,
      );
      await harness.credentialRepository.savePin('123456');
      harness.securityRepository.updateError = Exception('keystore write');

      final cleared = await harness.service.reset();

      expect(cleared, isFalse);
      expect(await harness.credentialRepository.hasPin(), isFalse);
    });
  });

  group('SecurityService lockout', () {
    test(
      'clears the failed attempt streak after a successful unlock',
      () async {
        final harness = SecurityTestHarness(now: () => now);
        final state = configuredState().copyWith(
          failedUnlockAttempts: 3,
          lockedUntil: now.add(const Duration(minutes: 1)),
        );

        final updated = await harness.service.markUnlocked(state);

        expect(updated.failedUnlockAttempts, 0);
        expect(updated.lockedUntil, isNull);
      },
    );

    test('locks out after five failed attempts', () async {
      final harness = SecurityTestHarness(now: () => now);
      final state = configuredState().copyWith(failedUnlockAttempts: 4);

      final updated = await harness.service.recordFailedAttempt(state);

      expect(updated.failedUnlockAttempts, 5);
      expect(
        updated.lockedUntil,
        now.add(SecurityService.lockoutDurationFor(5)),
      );
    });

    test('grows the lockout window with every failure', () {
      expect(SecurityService.lockoutDurationFor(4), Duration.zero);
      expect(SecurityService.lockoutDurationFor(5), const Duration(minutes: 1));
      expect(SecurityService.lockoutDurationFor(6), const Duration(minutes: 2));
      expect(SecurityService.lockoutDurationFor(7), const Duration(minutes: 4));
      expect(
        SecurityService.lockoutDurationFor(9),
        const Duration(minutes: 16),
      );
      expect(
        SecurityService.lockoutDurationFor(10),
        SecurityService.maxLockoutDuration,
      );
      expect(
        SecurityService.lockoutDurationFor(40),
        SecurityService.maxLockoutDuration,
      );
    });

    test('does not lock out while the lock is disabled', () async {
      final harness = SecurityTestHarness(now: () => now);
      final state = disabledState().copyWith(failedUnlockAttempts: 4);

      final updated = await harness.service.recordFailedAttempt(state);

      expect(updated.failedUnlockAttempts, 5);
      expect(updated.lockedUntil, isNull);
    });
  });

  group('SecurityService verifier', () {
    test('stores, reports, verifies and clears the PIN', () async {
      final harness = SecurityTestHarness(now: () => now);

      expect(await harness.service.hasPin(), isFalse);
      await harness.service.configurePin('123456');
      expect(await harness.service.hasPin(), isTrue);
      expect(await harness.service.verifyPin('123456'), isTrue);
      expect(await harness.service.verifyPin('654321'), isFalse);
      await harness.service.clearPin();
      expect(await harness.service.hasPin(), isFalse);
    });

    test('stores the configured lock metadata', () async {
      final harness = SecurityTestHarness(now: () => now);

      final state = await harness.service.saveConfiguredState(disabledState());

      expect(state.appLockEnabled, isTrue);
      expect(state.pinConfigured, isTrue);
      expect(state.failedUnlockAttempts, 0);
      expect(harness.securityRepository.state?.pinConfigured, isTrue);
    });
  });
}
