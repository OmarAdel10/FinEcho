import 'package:finecho/features/security/data/models/pin_verifier.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';

/// An in-memory salted-hash store used by tests and explicit in-memory graphs.
class InMemorySecurityCredentialRepository
    implements SecurityCredentialRepository {
  PinVerifier? _verifier;

  @override
  Future<bool> hasPin() async => _verifier != null;

  @override
  Future<bool> hasUnreadableLegacyData() async => false;

  @override
  Future<void> acknowledgeUnreadableLegacyData() async {}

  @override
  Future<void> savePin(String pin) async {
    _verifier = PinVerifier.create(pin);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final verifier = _verifier;
    if (verifier == null) {
      return false;
    }
    return verifier.matches(pin);
  }

  @override
  Future<void> clear() async {
    _verifier = null;
  }
}
