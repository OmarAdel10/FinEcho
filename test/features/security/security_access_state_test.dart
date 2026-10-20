import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final securityState = SecurityState(
    appLockEnabled: true,
    pinConfigured: true,
    failedUnlockAttempts: 0,
    secureKeyReady: true,
    updatedAt: DateTime.utc(2026, 10, 15, 12),
  );

  test('keeps the current status and message when copyWith omits them', () {
    final state = SecurityAccessState(
      securityState: securityState,
      status: SecurityAccessStatus.failure,
      errorMessage: 'Incorrect PIN. Try again.',
    );

    final copy = state.copyWith();

    expect(copy.status, SecurityAccessStatus.failure);
    expect(copy.errorMessage, 'Incorrect PIN. Try again.');
    expect(copy.securityState, securityState);
  });

  test('clears the message when the copy asks for it', () {
    final state = SecurityAccessState(
      securityState: securityState,
      status: SecurityAccessStatus.failure,
      errorMessage: 'Incorrect PIN. Try again.',
    );

    final copy = state.copyWith(clearErrorMessage: true);

    expect(copy.errorMessage, isNull);
    expect(copy.status, SecurityAccessStatus.failure);
  });

  test('reports the lock state from the security metadata', () {
    final locked = SecurityAccessState(
      securityState: securityState,
      status: SecurityAccessStatus.ready,
    );
    final unlocked = SecurityAccessState(
      securityState: securityState,
      status: SecurityAccessStatus.unlocked,
    );

    expect(locked.isLocked, isTrue);
    expect(locked.isSubmitting, isFalse);
    expect(locked.hasLoadError, isFalse);
    expect(unlocked.isLocked, isFalse);
  });
}
