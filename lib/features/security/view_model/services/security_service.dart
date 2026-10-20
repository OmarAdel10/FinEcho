import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';

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

  /// The duration of the temporary lockout.
  static const Duration lockoutDuration = Duration(minutes: 1);

  /// Loads persisted security state, or a safe disabled default.
  ///
  /// A verifier without lock metadata fails closed instead of silently
  /// unlocking the app.
  Future<SecurityState> load() async {
    final state = await _repository.get();
    if (state != null) {
      return state;
    }
    if (await _credentials.hasPin()) {
      return _defaultState().copyWith(
        appLockEnabled: true,
        pinConfigured: true,
      );
    }
    return _defaultState();
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
  Future<void> reset() async {
    await _repository.update(_defaultState());
    await _credentials.clear();
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
        lockedUntil: shouldLockOut ? _now().toUtc().add(lockoutDuration) : null,
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

  Future<SecurityState> _save(SecurityState state) async {
    await _repository.update(state);
    return state;
  }
}
