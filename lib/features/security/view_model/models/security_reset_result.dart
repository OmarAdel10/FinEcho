/// The outcome of erasing the app-lock data.
///
/// The erase and the acknowledgement of unreadable stored data are reported
/// separately, because a store that can be erased but cannot record the
/// acknowledgement leaves the app failing closed even though the PIN is
/// gone.
class SecurityResetResult {
  /// Creates a reset result.
  const new({required this.erased, required this.acknowledged});

  /// Whether the PIN verifier and the lock metadata were removed.
  final bool erased;

  /// Whether the store stopped reporting unreadable app-lock data.
  ///
  /// This is true when the store had nothing to report and when the
  /// acknowledgement was written successfully.
  final bool acknowledged;
}
