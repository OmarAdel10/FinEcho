import 'package:finecho/features/onboarding/view_model/models/onboarding_state.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:pinput/pinput.dart';

/// The security and app-lock setup step at the end of onboarding.
class SecuritySetupScreen extends StatelessWidget {
  /// Creates the security setup screen.
  const new({super.key});

  Future<void> _finishSetup({
    required BuildContext context,
    required String pin,
    required bool biometricsEnabled,
    required OnboardingCubit onboardingCubit,
    required SecurityCubit securityCubit,
  }) async {
    final configured = await securityCubit.configure(
      pin,
      biometricsEnabled: biometricsEnabled,
    );
    if (!configured) {
      return;
    }
    await onboardingCubit.enterSecuritySetup();
    final failure = await onboardingCubit.complete();
    if (!context.mounted) {
      return;
    }
    if (failure != null) {
      _showMessage(context, failure);
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security setup')),
      body: SafeArea(
        child: BlocConsumer<SecurityCubit, SecurityAccessState>(
          listener: (context, securityState) {
            if (securityState.status == SecurityAccessStatus.failure) {
              _showMessage(context, securityState.errorMessage);
            }
          },
          builder: (context, securityState) {
            return BlocBuilder<OnboardingCubit, OnboardingState>(
              builder: (context, state) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Protect your ledger',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose a six-digit PIN. Biometric unlock can be enabled '
                      'when your device supports it.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),
                    mui.Localizations(
                      locale: const Locale('en'),
                      delegates: const <LocalizationsDelegate<Object>>[
                        mui.DefaultMaterialLocalizations.delegate,
                        DefaultWidgetsLocalizations.delegate,
                      ],
                      child: mui.Material(
                        child: Pinput(
                          length: 6,
                          obscureText: true,
                          autofocus: true,
                          onChanged: (value) =>
                              context.read<OnboardingCubit>().setPin(value),
                        ),
                      ),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Use device biometrics'),
                      subtitle: const Text(
                        'Uses your device biometric unlock when available.',
                      ),
                      value: state.biometricsEnabled,
                      onChanged: (value) => context
                          .read<OnboardingCubit>()
                          .setBiometricsEnabled(value: value),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed:
                          state.isSubmitting || securityState.isSubmitting
                          ? null
                          : () => _finishSetup(
                              context: context,
                              pin: state.pin,
                              biometricsEnabled: state.biometricsEnabled,
                              onboardingCubit: context.read<OnboardingCubit>(),
                              securityCubit: context.read<SecurityCubit>(),
                            ),
                      child: Text(
                        state.isSubmitting || securityState.isSubmitting
                            ? 'Saving…'
                            : 'Finish setup',
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String? message) {
    if (message == null) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
