import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:finecho/features/security/view_model/models/security_reset_result.dart';

/// Coordinates FinEcho's app-lock rules and persistence.
class SecurityService {
  /// Creates a security coordinator.
  new({
    required SecurityRepository repository,
    required SecurityCredentialRepository credentials,
    DateTime Function()? now,
  }) : this._(repository, credentials, now ?? DateTime.now);

  new _(this._repository, this._credentials, this._now);

  final SecurityRepository _repository;
  final SecurityCredentialRepository _credentials;
  final DateTime Function() _now;

  /// The number of consecutive failures before a temporary lockout.
  static const int maxFailedAttemptsBeforeLockout = 5;

  /// The longest temporary lockout.
  static const Duration maxLockoutDuration = Duration(minutes: 30);

  /// The temporary lockout that follows [failedAttempts] failures.
  ///
  /// The window grows with every failure so a brute force cannot simply wait
  /// out a fixed cooldown. The streak is cleared by a successful unlock.
  static Duration lockoutDurationFor(int failedAttempts) {
    if (failedAttempts < maxFailedAttemptsBeforeLockout) {
      return Duration.zero;
    }
    final steps = failedAttempts - maxFailedAttemptsBeforeLockout;
    final minutes = 1 << steps;
    return Duration(
      minutes: minutes > maxLockoutDuration.inMinutes
          ? maxLockoutDuration.inMinutes
          : minutes,
    );
  }

  /// The current time used by the lockout rules.
  DateTime get now => _now().toUtc();

  /// Loads persisted security state and reconciles it with the verifier.
  ///
  /// A verifier without lock metadata fails closed, and lock metadata without
  /// a readable verifier reports an error so the recovery screen can reset it.
  /// Data written by an earlier storage backend that this build cannot read
  /// also fails closed, so an unreadable store is never mistaken for a fresh
  /// install.
  Future<SecurityState> load() async {
    if (await _credentials.hasUnreadableLegacyData()) {
      throw StateError('Stored app lock data cannot be read by this build.');
    }
    final state = await _repository.get();
    final hasPin = await _credentials.hasPin();

    if (state == null) {
      if (hasPin) {
        return await _persistConfigured(_defaultState());
      }
      return _defaultState();
    }

    if (state.appLockEnabled && state.pinConfigured) {
      if (!hasPin) {
        throw StateError('A configured app lock has no PIN verifier.');
      }
      return state;
    }

    if (hasPin) {
      return await _persistConfigured(state);
    }

    if (state.appLockEnabled || state.pinConfigured) {
      throw StateError('App lock metadata is incomplete.');
    }
    return state;
  }

  /// Stores a new six-digit PIN verifier.
  Future<void> configurePin(String pin) => _credentials.savePin(pin);

  /// Whether a PIN verifier is already stored.
  Future<bool> hasPin() => _credentials.hasPin();

  /// Removes the stored PIN verifier.
  Future<void> clearPin() => _credentials.clear();

  /// Returns whether the supplied PIN matches the configured verifier.
  Future<bool> verifyPin(String pin) => _credentials.verifyPin(pin);

  /// Clears app-lock metadata and the PIN verifier after a load failure.
  ///
  /// Each step is attempted independently so a partially broken secure store
  /// still has the best chance of recovery. The result reports the erase and
  /// the acknowledgement of unreadable stored data separately: a store that
  /// can be erased but cannot record the acknowledgement leaves the app
  /// failing closed, and the caller has to tell the user that the app data
  /// has to be cleared from the system settings.
  Future<SecurityResetResult> reset() async {
    var verifierCleared = false;
    var metadataCleared = false;
    try {
      await _credentials.clear();
      verifierCleared = true;
    } on Object {
      // The verifier stays, so the app keeps failing closed.
    }
    try {
      await _repository.update(_defaultState());
      metadataCleared = true;
    } on Object {
      // The metadata stays, so the app keeps failing closed.
    }
    var acknowledged = true;
    if (verifierCleared) {
      try {
        if (await _credentials.hasUnreadableLegacyData()) {
          await _credentials.acknowledgeUnreadableLegacyData();
        }
      } on Object {
        acknowledged = false;
      }
    } else {
      acknowledged = false;
    }
    return SecurityResetResult(
      erased: verifierCleared && metadataCleared,
      acknowledged: acknowledged,
    );
  }

  /// Clears a failed-attempt streak and temporary lockout after success.
  Future<SecurityState> markUnlocked(SecurityState state) {
    return _save(
      state.copyWith(
        failedUnlockAttempts: 0,
        clearLockedUntil: true,
        updatedAt: _now().toUtc(),
      ),
    );
  }

  /// Records a failed unlock attempt and applies lockout when required.
  Future<SecurityState> recordFailedAttempt(SecurityState state) {
    final attempts = state.failedUnlockAttempts + 1;
    final shouldLockOut =
        attempts >= maxFailedAttemptsBeforeLockout && state.appLockEnabled;

    return _save(
      state.copyWith(
        failedUnlockAttempts: attempts,
        lockedUntil: shouldLockOut
            ? _now().toUtc().add(lockoutDurationFor(attempts))
            : null,
        updatedAt: _now().toUtc(),
      ),
    );
  }

  /// Persists security metadata after setup.
  Future<SecurityState> saveConfiguredState(SecurityState state) {
    return _save(
      state.copyWith(
        appLockEnabled: true,
        pinConfigured: true,
        failedUnlockAttempts: 0,
        clearLockedUntil: true,
        updatedAt: _now().toUtc(),
      ),
    );
  }

  SecurityState _defaultState() {
    return SecurityState(
      appLockEnabled: false,
      pinConfigured: false,
      failedUnlockAttempts: 0,
      secureKeyReady: false,
      updatedAt: _now().toUtc(),
    );
  }

  Future<SecurityState> _persistConfigured(SecurityState state) async {
    final configured = state.copyWith(
      appLockEnabled: true,
      pinConfigured: true,
      updatedAt: _now().toUtc(),
    );
    try {
      await _repository.update(configured);
    } on Object {
      // The verifier still forces a locked state even if repair cannot persist.
    }
    return configured;
  }

  Future<SecurityState> _save(SecurityState state) async {
    await _repository.update(state);
    return state;
  }
}
