import 'package:finecho/features/onboarding/data/models/onboarding_step.dart';
import 'package:flutter/foundation.dart';

/// The persisted onboarding progress and user preferences.
@immutable
class OnboardingSnapshot {
  /// Creates an immutable onboarding snapshot.
  const new({
    required this.currentStep,
    required this.isCompleted,
    required this.biometricsEnabled,
    required this.smsAutomationEnabled,
  });

  /// The most recently visited onboarding step.
  final OnboardingStep currentStep;

  /// Whether the user has completed onboarding.
  final bool isCompleted;

  /// Whether the user wants to use device biometrics when available.
  final bool biometricsEnabled;

  /// Whether the user wants optional Android SMS automation.
  final bool smsAutomationEnabled;

  /// The snapshot used before onboarding has been stored.
  static const OnboardingSnapshot initial = OnboardingSnapshot(
    currentStep: OnboardingStep.privacy,
    isCompleted: false,
    biometricsEnabled: false,
    smsAutomationEnabled: false,
  );

  /// Returns a copy with the supplied non-null fields replaced.
  OnboardingSnapshot copyWith({
    OnboardingStep? currentStep,
    bool? isCompleted,
    bool? biometricsEnabled,
    bool? smsAutomationEnabled,
  }) {
    return OnboardingSnapshot(
      currentStep: currentStep ?? this.currentStep,
      isCompleted: isCompleted ?? this.isCompleted,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      smsAutomationEnabled: smsAutomationEnabled ?? this.smsAutomationEnabled,
    );
  }
}
