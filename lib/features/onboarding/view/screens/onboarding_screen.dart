import 'package:finecho/features/onboarding/data/models/onboarding_step.dart';
import 'package:finecho/features/onboarding/view_model/models/onboarding_state.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The three-page privacy, voice, and automation onboarding flow.
class OnboardingScreen extends StatelessWidget {
  /// Creates the onboarding screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            final stepIndex = state.currentStep.index + 1;
            return Text('Onboarding $stepIndex/3');
          },
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(
                    value:
                        (state.currentStep.index + 1) /
                        OnboardingStep.automation.index,
                  ),
                  const SizedBox(height: 32),
                  Expanded(child: _buildPage(state.currentStep)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (state.currentStep != OnboardingStep.privacy)
                        TextButton(
                          onPressed: () =>
                              context.read<OnboardingCubit>().previousStep(),
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => _handleContinue(context, state),
                        child: Text(
                          state.currentStep == OnboardingStep.automation
                              ? 'Set up security'
                              : 'Next',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.privacy => const _PrivacyPage(),
      OnboardingStep.voiceLogging => const _VoiceLoggingPage(),
      OnboardingStep.automation => const _AutomationPage(),
      OnboardingStep.securitySetup => const SizedBox.shrink(),
    };
  }

  Future<void> _handleContinue(
    BuildContext context,
    OnboardingState state,
  ) async {
    if (state.currentStep == OnboardingStep.automation) {
      context.go('/security-setup');
      return;
    }
    await context.read<OnboardingCubit>().nextStep();
  }
}

class _PrivacyPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingPage(
      icon: Icons.lock_outline,
      headline: 'Your money stays with you',
      description:
          'FinEcho keeps accounts, transactions, and budgets in '
          'encrypted local storage. No cloud account is required.',
    );
  }
}

class _VoiceLoggingPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingPage(
      icon: Icons.mic_none,
      headline: 'Say it. We log it locally.',
      description:
          'Speak a transaction, review the extracted details, and '
          'confirm it before anything is saved.',
    );
  }
}

class _AutomationPage extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return _OnboardingPage(
          icon: Icons.sms_outlined,
          headline: 'Optional SMS automation',
          description:
              'On Android, FinEcho can read matching financial '
              'messages and prepare a draft. You stay in control of '
              'permissions and confirmations.',
          trailing: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable SMS automation'),
            subtitle: const Text('Android only; you can change this later.'),
            value: state.smsAutomationEnabled,
            onChanged: (value) => context
                .read<OnboardingCubit>()
                .setSmsAutomationEnabled(value: value),
          ),
        );
      },
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const new({
    required this.icon,
    required this.headline,
    required this.description,
    this.trailing,
  });

  final IconData icon;
  final String headline;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          headline,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        if (trailing != null) ...[const SizedBox(height: 24), trailing!],
      ],
    );
  }
}
