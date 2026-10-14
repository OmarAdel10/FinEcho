import 'package:finecho/features/onboarding/view_model/models/onboarding_state.dart';
import 'package:finecho/features/onboarding/view_model/onboarding_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:pinput/pinput.dart';

/// The security and app-lock setup step at the end of onboarding.
class SecuritySetupScreen extends StatelessWidget {
  /// Creates the security setup screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security setup')),
      body: SafeArea(
        child: BlocConsumer<OnboardingCubit, OnboardingState>(
          listener: (context, state) {
            if (state.status == OnboardingStatus.completed) {
              context.go('/home');
            }
          },
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
                  onPressed: state.isSubmitting
                      ? null
                      : () => context.read<OnboardingCubit>().complete(),
                  child: Text(state.isSubmitting ? 'Saving…' : 'Finish setup'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
