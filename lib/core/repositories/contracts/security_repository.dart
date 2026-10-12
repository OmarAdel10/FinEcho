import 'package:finecho/core/models/security_state.dart';

/// Reads and updates FinEcho's non-secret security metadata.
abstract interface class SecurityRepository {
  /// Returns the singleton security state, or `null` before initialization.
  Future<SecurityState?> get();

  /// Upserts the supplied state into the singleton security row.
  Future<void> update(SecurityState state);
}
