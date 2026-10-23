/// Unlocks FinEcho with the device's enrolled biometric.
///
/// The interface keeps the app-lock ViewModel testable: the production
/// implementation wraps the platform plugin while tests inject a fake.
abstract interface class BiometricAuthenticator {
  /// Whether the device has an enrolled biometric and the platform can
  /// show the biometric prompt.
  Future<bool> isAvailable();

  /// Runs the platform biometric prompt and reports whether the user
  /// authenticated.
  ///
  /// Returns false when the user cancels or fails the prompt; the PIN
  /// always remains the fallback.
  Future<bool> authenticate({required String reason});
}
