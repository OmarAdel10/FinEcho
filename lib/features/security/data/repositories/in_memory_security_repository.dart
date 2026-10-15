import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';

/// An in-memory security store used until database-backed DI is integrated.
class InMemorySecurityRepository implements SecurityRepository {
  /// Creates a repository with the supplied initial state.
  new({SecurityState? initialState})
    : _state =
          initialState ??
          SecurityState(
            appLockEnabled: false,
            pinConfigured: false,
            failedUnlockAttempts: 0,
            secureKeyReady: false,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          );

  SecurityState? _state;

  @override
  Future<SecurityState?> get() async => _state;

  @override
  Future<void> update(SecurityState state) async {
    _state = state;
  }
}
