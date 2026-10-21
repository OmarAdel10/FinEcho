/// Stores FinEcho's app-lock PIN verifier without retaining the raw PIN.
abstract interface class SecurityCredentialRepository {
  /// Whether a PIN verifier has been configured.
  Future<bool> hasPin();

  /// Whether the store still holds data written by an earlier storage backend
  /// that this build cannot read.
  ///
  /// A store that reports unreadable data must never be read as a fresh
  /// install, because that would silently drop the app lock.
  Future<bool> hasUnreadableLegacyData();

  /// Records that the unreadable legacy data was deliberately discarded.
  ///
  /// The acknowledgement is kept in the current backend so the app does not
  /// ask the user to erase the app lock again on every start.
  Future<void> acknowledgeUnreadableLegacyData();

  /// Replaces the stored PIN verifier.
  Future<void> savePin(String pin);

  /// Returns whether the supplied PIN matches the stored verifier.
  Future<bool> verifyPin(String pin);

  /// Removes the stored PIN verifier.
  Future<void> clear();
}
