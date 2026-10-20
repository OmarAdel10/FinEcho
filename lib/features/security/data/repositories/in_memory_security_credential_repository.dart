import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/security_pin_hasher.dart';

/// An in-memory salted-hash store used by tests and explicit in-memory graphs.
class InMemorySecurityCredentialRepository
    implements SecurityCredentialRepository {
  String? _salt;
  String? _pinHash;

  @override
  Future<bool> hasPin() async => _pinHash != null;

  @override
  Future<void> savePin(String pin) async {
    final salt = SecurityPinHasher.createSalt();
    _salt = salt;
    _pinHash = SecurityPinHasher.hash(pin, salt);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final salt = _salt;
    final pinHash = _pinHash;
    if (salt == null || pinHash == null) {
      return false;
    }
    return SecurityPinHasher.matches(
      pin: pin,
      salt: salt,
      expectedHash: pinHash,
    );
  }

  @override
  Future<void> clear() async {
    _salt = null;
    _pinHash = null;
  }
}
