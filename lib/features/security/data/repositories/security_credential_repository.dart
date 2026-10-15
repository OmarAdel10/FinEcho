/// Stores FinEcho's app-lock PIN verifier without retaining the raw PIN.
abstract interface class SecurityCredentialRepository {
  /// Whether a PIN verifier has been configured.
  Future<bool> hasPin();

  /// Replaces the stored PIN verifier.
  Future<void> savePin(String pin);

  /// Returns whether the supplied PIN matches the stored verifier.
  Future<bool> verifyPin(String pin);

  /// Removes the stored PIN verifier.
  Future<void> clear();
}
