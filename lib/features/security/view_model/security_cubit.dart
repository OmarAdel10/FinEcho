import 'package:bloc/bloc.dart';
import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/services/security_service.dart';

/// The app-lock ViewModel.
class SecurityCubit extends Cubit<SecurityAccessState> {
  /// Creates an app-lock ViewModel.
  new(SecurityService service, {this.loadTimeout = const Duration(seconds: 5)})
    : _service = service,
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

  /// The maximum time a security read may take before the app fails closed.
  final Duration loadTimeout;

  int _lockEpoch = 0;

  /// Loads the persisted security snapshot.
  Future<void> load() async {
    if (isClosed) {
      return;
    }
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
      emit(
        SecurityAccessState(
          securityState: securityState,
          status: securityState.appLockEnabled && securityState.pinConfigured
              ? SecurityAccessStatus.ready
              : SecurityAccessStatus.unlocked,
        ),
      );
    } on Object {
      if (isClosed) {
        return;
      }
      emit(
        SecurityAccessState(
          securityState: state.securityState,
          status: SecurityAccessStatus.error,
          errorMessage: 'Could not load security settings. Please try again.',
        ),
      );
    }
  }

  /// Relocks the app without changing the persisted security state.
  ///
  /// Does nothing when the app lock is disabled or no PIN is configured.
  void lock() {
    if (isClosed) {
      return;
    }
    final securityState = state.securityState;
    if (!securityState.appLockEnabled || !securityState.pinConfigured) {
      return;
    }
    _lockEpoch++;
    emit(
      SecurityAccessState(
        securityState: securityState,
        status: SecurityAccessStatus.ready,
      ),
    );
  }

  /// Configures the app lock with a six-digit PIN.
  Future<bool> configure(String pin) async {
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
        state.securityState,
      );
      if (isClosed) {
        return true;
      }
      emit(
        SecurityAccessState(
          securityState: securityState,
          status: SecurityAccessStatus.unlocked,
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

  /// Clears app-lock metadata and the verifier after an unrecoverable load.
  Future<bool> resetLock() async {
    if (isClosed) {
      return false;
    }
    emit(
      state.copyWith(
        status: SecurityAccessStatus.submitting,
        clearErrorMessage: true,
      ),
    );
    final reset = await _service.reset();
    if (isClosed) {
      return false;
    }
    if (!reset) {
      emit(
        SecurityAccessState(
          securityState: state.securityState,
          status: SecurityAccessStatus.error,
          errorMessage:
              'Could not reset app lock. Clear FinEcho app data '
              'from system settings and relaunch.',
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
        ),
      );
      return false;
    }
    return true;
  }

  /// Verifies the six-digit PIN and unlocks the app on success.
  Future<bool> unlockWithPin(String pin) async {
    if (state.status == SecurityAccessStatus.submitting) {
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
    if (state.isLockedOut) {
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
          status: SecurityAccessStatus.failure,
          errorMessage: 'Could not verify PIN. Please try again.',
        ),
      );
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
