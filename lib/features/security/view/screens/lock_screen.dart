import 'dart:async';

import 'package:finecho/features/security/view_model/models/security_access_state.dart';
import 'package:finecho/features/security/view_model/security_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:pinput/pinput.dart';

/// The PIN fallback screen shown while FinEcho is locked.
class LockScreen extends StatefulWidget {
  /// Creates the lock screen.
  const new({this.pinController, super.key});

  /// An optional externally owned PIN controller, used by tests and embedders.
  final TextEditingController? pinController;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final TextEditingController _pinController =
      widget.pinController ?? TextEditingController();
  late final bool _ownsPinController = widget.pinController == null;
  bool _biometricPromptShown = false;

  @override
  void dispose() {
    if (_ownsPinController) {
      _pinController.dispose();
    }
    super.dispose();
  }

  Future<void> _unlock(String pin) async {
    await context.read<SecurityCubit>().unlockWithPin(pin);
  }

  Future<void> _unlockWithBiometrics() async {
    await context.read<SecurityCubit>().unlockWithBiometrics();
  }

  void _maybeAutoPromptBiometrics(SecurityAccessState state) {
    if (_biometricPromptShown || !state.canUseBiometrics) {
      return;
    }
    _biometricPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_unlockWithBiometrics());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unlock FinEcho')),
      body: SafeArea(
        child: BlocConsumer<SecurityCubit, SecurityAccessState>(
          listener: (context, state) {
            if (state.status == SecurityAccessStatus.failure ||
                state.status == SecurityAccessStatus.ready) {
              _pinController.clear();
            }
          },
          builder: (context, state) {
            _maybeAutoPromptBiometrics(state);
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Your ledger is locked',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter your six-digit PIN to continue.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
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
                      controller: _pinController,
                      length: 6,
                      obscureText: true,
                      autofocus: true,
                      onChanged: (pin) {
                        if (pin.length == 6) {
                          unawaited(_unlock(pin));
                        }
                      },
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
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => _unlock(_pinController.text),
                  child: Text(state.isSubmitting ? 'Verifying…' : 'Unlock'),
                ),
                if (state.canUseBiometrics) ...[
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: state.isSubmitting
                        ? null
                        : _unlockWithBiometrics,
                    child: const Text('Use biometrics'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
