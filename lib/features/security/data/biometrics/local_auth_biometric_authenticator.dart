import 'package:finecho/features/security/data/biometrics/biometric_authenticator.dart';
import 'package:local_auth/local_auth.dart';

/// A [BiometricAuthenticator] backed by the `local_auth` platform plugin.
class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  /// Creates an authenticator over the platform plugin.
  const new([LocalAuthentication? plugin]) : _plugin = plugin;

  final LocalAuthentication? _plugin;

  LocalAuthentication get _instance => _plugin ?? LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _instance.canCheckBiometrics &&
          await _instance.isDeviceSupported();
    } on Object {
      // The platform cannot answer, so the biometric path stays hidden and
      // the PIN remains the only unlock.
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _instance.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on Object {
      // A platform error means the prompt could not run; the PIN fallback
      // stays available.
      return false;
    }
  }
}
