import 'package:finecho/core/models/security_state.dart';
import 'package:flutter/foundation.dart';

/// The lifecycle of FinEcho's app-lock ViewModel.
enum SecurityAccessStatus {
  /// Security state has not been loaded.
  loading,

  /// Security state is ready and the app is locked if required.
  ready,

  /// A security operation is being persisted or verified.
  submitting,

  /// The app-lock data is being erased after an unrecoverable load.
  resetting,

  /// The user has successfully unlocked the app.
  unlocked,

  /// The requested security operation failed.
  failure,

  /// Persisted security state could not be loaded.
  error,
}

/// Immutable security state rendered by app-lock views.
@immutable
class SecurityAccessState {
  /// Creates an immutable security access state.
  const new({
    required this.securityState,
    this.status = SecurityAccessStatus.loading,
    this.errorMessage,
    this.canEraseAppLock = false,
    this.biometricsAvailable = false,
  });

  /// The persisted, non-secret security metadata.
  final SecurityState securityState;

  /// The current security ViewModel lifecycle.
  final SecurityAccessStatus status;

  /// A user-facing error, when present.
  final String? errorMessage;

  /// Whether the destructive erase may be offered to the user.
  ///
  /// The erase removes the PIN verifier without checking it, so it is only
  /// offered when the stored app-lock data cannot be read at all.
  final bool canEraseAppLock;

  /// Whether the device currently has an enrolled biometric the platform
  /// can prompt with.
  final bool biometricsAvailable;

  /// Whether the app should show the lock UI instead of protected content.
  bool get isLocked =>
      securityState.appLockEnabled &&
      securityState.pinConfigured &&
      status != SecurityAccessStatus.unlocked;

  /// Whether the locked app can offer the biometric unlock prompt.
  bool get canUseBiometrics =>
      securityState.appLockEnabled &&
      securityState.pinConfigured &&
      securityState.biometricsEnabled &&
      biometricsAvailable &&
      status != SecurityAccessStatus.unlocked &&
      status != SecurityAccessStatus.submitting;

  /// Whether a security operation is in progress.
  bool get isSubmitting =>
      status == SecurityAccessStatus.submitting ||
      status == SecurityAccessStatus.resetting;

  /// Whether persisted security state could not be loaded.
  bool get hasLoadError => status == SecurityAccessStatus.error;

  /// Whether the app is inside a temporary lockout window at [now].
  ///
  /// The caller supplies the clock so the window can be evaluated against the
  /// same time source the lockout rules use.
  bool isLockedOutAt(DateTime now) {
    final lockedUntil = securityState.lockedUntil;
    return lockedUntil != null && now.toUtc().isBefore(lockedUntil);
  }

  /// Returns a copy with the supplied non-null fields replaced.
  SecurityAccessState copyWith({
    SecurityState? securityState,
    SecurityAccessStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? canEraseAppLock,
    bool? biometricsAvailable,
  }) {
    return SecurityAccessState(
      securityState: securityState ?? this.securityState,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      canEraseAppLock: canEraseAppLock ?? this.canEraseAppLock,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
    );
  }
}
