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
  });

  /// The persisted, non-secret security metadata.
  final SecurityState securityState;

  /// The current security ViewModel lifecycle.
  final SecurityAccessStatus status;

  /// A user-facing error, when present.
  final String? errorMessage;

  /// Whether the app should show the lock UI instead of protected content.
  bool get isLocked =>
      securityState.appLockEnabled &&
      securityState.pinConfigured &&
      status != SecurityAccessStatus.unlocked;

  /// Whether a security operation is in progress.
  bool get isSubmitting =>
      status == SecurityAccessStatus.submitting ||
      status == SecurityAccessStatus.resetting;

  /// Whether persisted security state could not be loaded.
  bool get hasLoadError => status == SecurityAccessStatus.error;

  /// Whether the app is currently inside a temporary lockout window.
  bool get isLockedOut {
    final lockedUntil = securityState.lockedUntil;
    return lockedUntil != null && DateTime.now().toUtc().isBefore(lockedUntil);
  }

  /// Returns a copy with the supplied non-null fields replaced.
  SecurityAccessState copyWith({
    SecurityState? securityState,
    SecurityAccessStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SecurityAccessState(
      securityState: securityState ?? this.securityState,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
