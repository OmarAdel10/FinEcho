import 'package:bloc/bloc.dart';
import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/data/biometrics/biometric_authenticator.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/services/security_service.dart';

/// The app-lock ViewModel.
class SecurityCubit extends Cubit<SecurityAccessState> {
  /// Creates an app-lock ViewModel.
  new(
    SecurityService service, {
    this._biometrics,
    this.loadTimeout = const Duration(seconds: 5),
  }) : _service = service,
       super(
         SecurityAccessState(
           securityState: SecurityState(
             appLockEnabled: false,
             pinConfigured: false,
             failedUnlockAttempts: 0,
             secureKeyReady: false,
             updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
           ),
         ),
       );

  final SecurityService _service;

  /// Prompts the device biometric; null hides the biometric unlock path.
  final BiometricAuthenticator? _biometrics;

  /// The maximum time a security read may take before the app fails closed.
  final Duration loadTimeout;

  int _lockEpoch = 0;

  /// Whether the app is inside a temporary lockout window.
  ///
  /// The lockout rules and this check share one clock, so the window never
  /// depends on the wall clock the app happens to run on.
  bool get isLockedOut => state.isLockedOutAt(_service.now);

  /// Loads the persisted security snapshot.
  ///
  /// The lock epoch is captured before the first await, so a load that
  /// finishes after the app was backgrounded cannot resurrect the unlocked
  /// state.
  Future<void> load() async {
    if (isClosed) {
      return;
    }
    final lockEpoch = _lockEpoch;
    final wasUnlocked = state.status == SecurityAccessStatus.unlocked;
    emit(
      state.copyWith(
        status: SecurityAccessStatus.loading,
        clearErrorMessage: true,
      ),
    );
    try {
      final securityState = await _service.load().timeout(loadTimeout);
      if (isClosed) {
        return;
      }
      final configured =
          securityState.appLockEnabled && securityState.pinConfigured;
      final relocked = lockEpoch != _lockEpoch;
      final biometricsAvailable = await _checkBiometrics(
        securityState.biometricsEnabled,
      );
      if (isClosed) {
        return;
      }
      emit(
        SecurityAccessState(
          securityState: securityState,
          status: configured
              ? wasUnlocked && !relocked
                    ? SecurityAccessStatus.unlocked
                    : SecurityAccessStatus.ready
              : SecurityAccessStatus.unlocked,
          biometricsAvailable: biometricsAvailable,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }
      emit(
        SecurityAccessState(
          securityState: state.securityState,
          status: SecurityAccessStatus.error,
          errorMessage: 'Could not load security settings. Please try again.',
          canEraseAppLock: _isUnreadableData(error),
        ),
      );
    }
  }

  /// Relocks the app without changing the persisted security state.
  ///
  /// Does nothing when the app lock is disabled or no PIN is configured. The
  /// lock epoch always moves, so an unlock or a setup that is still running
  /// cannot complete after the app was backgrounded.
  void lock() {
    if (isClosed) {
      return;
    }
    _lockEpoch++;
    final securityState = state.securityState;
    if (!securityState.appLockEnabled || !securityState.pinConfigured) {
      return;
    }
    emit(
      SecurityAccessState(
        securityState: securityState,
        status: SecurityAccessStatus.ready,
        biometricsAvailable: state.biometricsAvailable,
      ),
    );
  }

  /// Configures the app lock with a six-digit PIN.
  ///
  /// When the app is backgrounded while the setup is running, the PIN is
  /// still stored but the app stays locked, so a setup can never leave the
  /// app unlocked in the background.
  ///
  /// The [biometricsEnabled] preference from the setup screen is persisted
  /// with the lock metadata so the unlock flow can offer the biometric
  /// prompt on later launches.
  Future<bool> configure(String pin, {bool biometricsEnabled = false}) async {
    if (state.isSubmitting) {
      return false;
    }
    final lockEpoch = _lockEpoch;
    if (pin.length != 6) {
      emit(
        state.copyWith(
          status: SecurityAccessStatus.failure,
          errorMessage: 'Enter a six-digit PIN.',
        ),
      );
      return false;
    }

    try {
      if (state.securityState.pinConfigured || await _service.hasPin()) {
        emit(
          state.copyWith(
            status: SecurityAccessStatus.failure,
            errorMessage: 'App lock is already configured.',
          ),
        );
        return false;
      }
    } on Object {
      emit(
        state.copyWith(
          status: SecurityAccessStatus.failure,
          errorMessage: 'Could not check app lock. Please try again.',
        ),
      );
      return false;
    }

    emit(state.copyWith(status: SecurityAccessStatus.submitting));
    try {
      await _service.configurePin(pin);
      final securityState = await _service.saveConfiguredState(
        state.securityState.copyWith(biometricsEnabled: biometricsEnabled),
      );
      if (isClosed) {
        return true;
      }
      final relocked = lockEpoch != _lockEpoch;
      final biometricsAvailable = await _checkBiometrics(biometricsEnabled);
      if (isClosed) {
        return true;
      }
      emit(
        SecurityAccessState(
          securityState: securityState,
          status: relocked
              ? SecurityAccessStatus.ready
              : SecurityAccessStatus.unlocked,
          biometricsAvailable: biometricsAvailable,
        ),
      );
      return true;
    } on Object {
      final cleared = await _clearPinAfterFailedSetup();
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: SecurityAccessStatus.failure,
          errorMessage: cleared
              ? 'Could not save app lock. Please try again.'
              : 'Could not finish setting up app lock. Clear FinEcho app data '
                    'from system settings and relaunch.',
        ),
      );
      return false;
    }
  }

  /// Whether a load failure means the stored app-lock data cannot be read.
  ///
  /// A corrupt payload, and a store that raised because it could not prove
  /// that its entries are readable, are both treated as unreadable: a read
  /// may silently return an empty value. A timeout or a transient platform
  /// error can be retried instead, so the erase stays hidden in that case.
  static bool _isUnreadableData(Object error) {
    return error is StateError || error is FormatException;
  }

  /// Clears app-lock metadata and the verifier after an unrecoverable load.
  Future<bool> resetLock() async {
    if (isClosed) {
      return false;
    }
    emit(
      state.copyWith(
        status: SecurityAccessStatus.resetting,
        clearErrorMessage: true,
      ),
    );
    final result = await _service.reset();
    if (isClosed) {
      return false;
    }
    if (!result.erased) {
      emit(
        SecurityAccessState(
          securityState: state.securityState,
          status: SecurityAccessStatus.error,
          errorMessage:
              'Could not reset app lock. Clear FinEcho app data '
              'from system settings and relaunch.',
          canEraseAppLock: true,
        ),
      );
      return false;
    }
    if (!result.acknowledged) {
      emit(
        SecurityAccessState(
          securityState: state.securityState,
          status: SecurityAccessStatus.error,
          errorMessage:
              'The app lock was erased, but this app still cannot read its '
              'storage. Clear FinEcho app data from system settings and '
              'relaunch.',
          canEraseAppLock: true,
        ),
      );
      return false;
    }
    await load();
    if (isClosed) {
      return false;
    }
    if (state.status == SecurityAccessStatus.error) {
      emit(
        SecurityAccessState(
          securityState: state.securityState,
          status: SecurityAccessStatus.error,
          errorMessage: 'Could not reload app lock settings. Tap Try again.',
          canEraseAppLock: state.canEraseAppLock,
        ),
      );
      return false;
    }
    return true;
  }

  /// Verifies the six-digit PIN and unlocks the app on success.
  Future<bool> unlockWithPin(String pin) async {
    if (state.isSubmitting) {
      return false;
    }
    if (pin.length != 6) {
      emit(
        state.copyWith(
          status: SecurityAccessStatus.failure,
          errorMessage: 'Enter a six-digit PIN.',
        ),
      );
      return false;
    }

    emit(state.copyWith(status: SecurityAccessStatus.submitting));
    if (isLockedOut) {
      emit(
        state.copyWith(
          status: SecurityAccessStatus.failure,
          errorMessage: 'Too many attempts. Try again later.',
        ),
      );
      return false;
    }

    final lockEpoch = _lockEpoch;
    try {
      final matches = await _service.verifyPin(pin);
      if (!matches) {
        final securityState = await _service.recordFailedAttempt(
          state.securityState,
        );
        if (isClosed) {
          return false;
        }
        emit(
          SecurityAccessState(
            securityState: securityState,
            status: SecurityAccessStatus.failure,
            errorMessage: securityState.lockedUntil == null
                ? 'Incorrect PIN. Try again.'
                : 'Too many attempts. Try again later.',
          ),
        );
        return false;
      }

      if (lockEpoch != _lockEpoch) {
        return false;
      }
      final securityState = await _service.markUnlocked(state.securityState);
      if (isClosed || lockEpoch != _lockEpoch) {
        return false;
      }
      emit(
        SecurityAccessState(
          securityState: securityState,
          status: SecurityAccessStatus.unlocked,
        ),
      );
      return true;
    } on Object {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: SecurityAccessStatus.error,
          errorMessage: 'Could not verify PIN. Please try again.',
          canEraseAppLock: false,
        ),
      );
      return false;
    }
  }

  /// Unlocks the app with the device biometric.
  ///
  /// A cancelled or failed prompt keeps the app locked without recording a
  /// failed PIN attempt, so the lockout streak only grows on PIN entry. The
  /// biometric prompt cannot run while the app is inside a lockout window,
  /// because the lock would then be bypassable.
  Future<bool> unlockWithBiometrics() async {
    final biometrics = _biometrics;
    if (biometrics == null ||
        state.isSubmitting ||
        isLockedOut ||
        !state.canUseBiometrics) {
      return false;
    }

    final lockEpoch = _lockEpoch;
    emit(
      state.copyWith(
        status: SecurityAccessStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final authenticated = await biometrics.authenticate(
      reason: 'Unlock your FinEcho ledger',
    );
    if (isClosed) {
      return false;
    }
    if (!authenticated) {
      emit(
        state.copyWith(
          status: SecurityAccessStatus.failure,
          errorMessage: 'Biometric unlock was cancelled. Enter your PIN.',
        ),
      );
      return false;
    }
    if (lockEpoch != _lockEpoch) {
      return false;
    }
    final securityState = await _service.markUnlocked(state.securityState);
    if (isClosed || lockEpoch != _lockEpoch) {
      return false;
    }
    emit(
      SecurityAccessState(
        securityState: securityState,
        status: SecurityAccessStatus.unlocked,
        biometricsAvailable: state.biometricsAvailable,
      ),
    );
    return true;
  }

  /// Reports whether the biometric prompt can run, when it is wired.
  Future<bool> _checkBiometrics(bool enabled) async {
    if (!enabled) {
      return false;
    }
    final biometrics = _biometrics;
    if (biometrics == null) {
      return false;
    }
    try {
      return await biometrics.isAvailable();
    } on Object {
      return false;
    }
  }

  Future<bool> _clearPinAfterFailedSetup() async {
    try {
      await _service.clearPin();
      return true;
    } on Object {
      return false;
    }
  }
}
