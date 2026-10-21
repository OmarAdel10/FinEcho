import 'package:finecho/features/onboarding/data/models/onboarding_step.dart';
import 'package:finecho/features/onboarding/view_model/models/onboarding_state.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/onboarding/view_model/services/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_onboarding_repository.dart';

void main() {
  late FakeOnboardingRepository repository;
  late OnboardingCubit cubit;

  setUp(() {
    repository = FakeOnboardingRepository();
    cubit = OnboardingCubit(OnboardingService(repository));
  });

  tearDown(() async {
    await cubit.close();
  });

  group('OnboardingCubit', () {
    test('loads the persisted snapshot', () async {
      await cubit.load();

      expect(cubit.state.status, OnboardingStatus.ready);
      expect(cubit.state.currentStep, OnboardingStep.privacy);
    });

    test('advances and persists progress', () async {
      await cubit.load();
      await cubit.nextStep();

      expect(cubit.state.currentStep, OnboardingStep.voiceLogging);
      expect(repository.saved, hasLength(1));
      expect(repository.saved.single.currentStep, OnboardingStep.voiceLogging);
    });

    test('returns to the previous step', () async {
      await cubit.load();
      await cubit.nextStep();
      cubit.previousStep();

      expect(cubit.state.currentStep, OnboardingStep.privacy);
    });

    test('stores the biometric preference', () async {
      await cubit.load();

      cubit.setBiometricsEnabled(value: true);

      expect(cubit.state.biometricsEnabled, isTrue);
    });

    test('stores the SMS automation preference', () async {
      await cubit.load();

      cubit.setSmsAutomationEnabled(value: true);

      expect(cubit.state.smsAutomationEnabled, isTrue);
    });

    test('enters the security setup step and persists it', () async {
      await cubit.load();
      await cubit.enterSecuritySetup();

      expect(cubit.state.currentStep, OnboardingStep.securitySetup);
      expect(repository.saved.single.currentStep, OnboardingStep.securitySetup);
      expect(repository.saved.single.isCompleted, isFalse);
    });

    test(
      'completes onboarding after entering the security setup step',
      () async {
        await cubit.load();
        await cubit.enterSecuritySetup();
        cubit.setPin('123456');

        final failure = await cubit.complete();

        expect(failure, isNull);
        expect(cubit.state.status, OnboardingStatus.completed);
        expect(repository.saved.last.isCompleted, isTrue);
      },
    );

    test(
      'ignores the security setup step before the snapshot is loaded',
      () async {
        await cubit.enterSecuritySetup();

        expect(cubit.state.currentStep, OnboardingStep.privacy);
        expect(repository.saved, isEmpty);
      },
    );

    test('completes onboarding with a six-digit PIN', () async {
      await cubit.load();
      await cubit.nextStep();
      await cubit.nextStep();
      await cubit.nextStep();
      cubit.setPin('123456');
      final failure = await cubit.complete();

      expect(failure, isNull);
      expect(cubit.state.status, OnboardingStatus.completed);
      expect(repository.saved.last.isCompleted, isTrue);
      expect(repository.saved.last.currentStep, OnboardingStep.securitySetup);
    });

    test('rejects completion with an incomplete PIN', () async {
      await cubit.load();
      await cubit.nextStep();
      await cubit.nextStep();
      await cubit.nextStep();
      cubit.setPin('12345');
      final failure = await cubit.complete();

      expect(failure, 'Enter a six-digit PIN.');
      expect(cubit.state.status, OnboardingStatus.failure);
      expect(cubit.state.errorMessage, 'Enter a six-digit PIN.');
      expect(
        repository.saved.where((snapshot) => snapshot.isCompleted),
        isEmpty,
      );
    });

    test('reports a persistence failure during completion', () async {
      repository.saveError = Exception('save failed');
      await cubit.load();
      await cubit.nextStep();
      await cubit.nextStep();
      await cubit.nextStep();
      cubit.setPin('123456');
      repository.saveError = Exception('save failed');
      final failure = await cubit.complete();

      expect(failure, 'Could not save the onboarding preferences.');
      expect(cubit.state.status, OnboardingStatus.failure);
      expect(
        cubit.state.errorMessage,
        contains('Could not save the onboarding preferences'),
      );
    });
  });
}
