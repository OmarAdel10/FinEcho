import 'package:finecho/features/onboarding/data/models/onboarding_snapshot.dart';
import 'package:finecho/features/onboarding/data/models/onboarding_step.dart';
import 'package:finecho/features/onboarding/view_model/models/onboarding_state.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The onboarding ViewModel.
class OnboardingCubit extends Cubit<OnboardingState> {
  /// Creates an onboarding ViewModel.
  new(this._service) : super(const OnboardingState());

  final OnboardingService _service;

  /// Loads the persisted onboarding snapshot into an immutable state.
  Future<void> load() async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    final snapshot = await _service.load();
    if (isClosed) {
      return;
    }
    emit(
      OnboardingState(
        status: OnboardingStatus.ready,
        currentStep: snapshot.currentStep,
        biometricsEnabled: snapshot.biometricsEnabled,
        smsAutomationEnabled: snapshot.smsAutomationEnabled,
      ),
    );
  }

  /// Moves to the next onboarding step and persists progress.
  Future<void> nextStep() async {
    if (state.status != OnboardingStatus.ready) {
      return;
    }
    final nextIndex = state.currentStep.index + 1;
    if (nextIndex >= OnboardingStep.values.length) {
      return;
    }
    final nextStep = OnboardingStep.values[nextIndex];
    emit(state.copyWith(currentStep: nextStep));
    await _persistProgress();
  }

  /// Moves to the previous onboarding step without persisting backward motion.
  void previousStep() {
    if (state.status != OnboardingStatus.ready ||
        state.currentStep == OnboardingStep.privacy) {
      return;
    }
    final previousStep = OnboardingStep.values[state.currentStep.index - 1];
    emit(state.copyWith(currentStep: previousStep, clearErrorMessage: true));
  }

  /// Updates the biometric preference.
  void setBiometricsEnabled({required bool value}) {
    emit(state.copyWith(biometricsEnabled: value));
  }

  /// Updates the optional Android SMS automation preference.
  void setSmsAutomationEnabled({required bool value}) {
    emit(state.copyWith(smsAutomationEnabled: value));
  }

  /// Updates the six-digit PIN being configured.
  void setPin(String value) {
    emit(state.copyWith(pin: value, clearErrorMessage: value.length == 6));
  }

  /// Marks the security setup step as reached so setup can be completed.
  ///
  /// The security setup screen is the last onboarding step, so reaching it
  /// moves the onboarding progress to [OnboardingStep.securitySetup] and
  /// persists that progress.
  Future<void> enterSecuritySetup() async {
    if (state.status != OnboardingStatus.ready ||
        state.currentStep == OnboardingStep.securitySetup) {
      return;
    }
    emit(state.copyWith(currentStep: OnboardingStep.securitySetup));
    await _persistProgress();
  }

  /// Validates and persists onboarding completion.
  Future<bool> complete() async {
    if (state.currentStep != OnboardingStep.securitySetup ||
        state.pin.length != 6) {
      emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: 'Enter a six-digit PIN.',
        ),
      );
      return false;
    }

    emit(state.copyWith(status: OnboardingStatus.submitting));
    try {
      await _service.save(
        OnboardingSnapshot(
          currentStep: OnboardingStep.securitySetup,
          isCompleted: true,
          biometricsEnabled: state.biometricsEnabled,
          smsAutomationEnabled: state.smsAutomationEnabled,
        ),
      );
      if (isClosed) {
        return true;
      }
      emit(state.copyWith(status: OnboardingStatus.completed));
      return true;
    } on Exception {
      if (isClosed) {
        return false;
      }
      emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: 'Could not finish setup. Please try again.',
        ),
      );
      return false;
    }
  }

  Future<void> _persistProgress() async {
    try {
      await _service.save(
        OnboardingSnapshot(
          currentStep: state.currentStep,
          isCompleted: false,
          biometricsEnabled: state.biometricsEnabled,
          smsAutomationEnabled: state.smsAutomationEnabled,
        ),
      );
    } on Exception {
      // Progress persistence is best effort while setup remains in progress.
    }
  }
}
