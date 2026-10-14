import 'package:finecho/features/onboarding/data/models/onboarding_step.dart';
import 'package:flutter/foundation.dart';

/// The lifecycle of the onboarding ViewModel.
enum OnboardingStatus {
  /// Initial state before the saved snapshot is loaded.
  loading,

  /// Onboarding is ready to render.
  ready,

  /// Completion is being persisted.
  submitting,

  /// Onboarding has been completed successfully.
  completed,

  /// Onboarding could not be completed.
  failure,
}

/// Immutable state rendered by onboarding views.
@immutable
class OnboardingState {
  /// Creates an immutable onboarding state.
  const new({
    this.status = OnboardingStatus.loading,
    this.currentStep = OnboardingStep.privacy,
    this.biometricsEnabled = false,
    this.smsAutomationEnabled = false,
    this.pin = '',
    this.errorMessage,
  });

  /// The current ViewModel lifecycle status.
  final OnboardingStatus status;

  /// The current onboarding step.
  final OnboardingStep currentStep;

  /// Whether device biometrics should be used when available.
  final bool biometricsEnabled;

  /// Whether optional Android SMS automation is enabled.
  final bool smsAutomationEnabled;

  /// The six-digit PIN currently being configured.
  final String pin;

  /// A user-facing error, when present.
  final String? errorMessage;

  /// Whether the entered PIN has the required length.
  bool get isPinComplete => pin.length == 6;

  /// Whether the ViewModel is waiting for a persistence operation.
  bool get isSubmitting => status == OnboardingStatus.submitting;

  /// Returns a copy with the supplied non-null fields replaced.
  OnboardingState copyWith({
    OnboardingStatus? status,
    OnboardingStep? currentStep,
    bool? biometricsEnabled,
    bool? smsAutomationEnabled,
    String? pin,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      smsAutomationEnabled: smsAutomationEnabled ?? this.smsAutomationEnabled,
      pin: pin ?? this.pin,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
