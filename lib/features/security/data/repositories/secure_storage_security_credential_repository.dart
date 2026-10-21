import 'package:finecho/features/security/data/models/pin_verifier.dart';
import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:finecho/features/security/data/storage/secure_key_value_store.dart';

/// Persists the salted PIN verifier in platform secure storage.
class SecureStorageSecurityCredentialRepository
    implements SecurityCredentialRepository {
  /// Creates a repository over [store].
  const new({required this.store});

  /// The secure-storage key holding the PIN verifier.
  ///
  /// The key is historical; the payload carries its own format version.
  static const String credentialKey = 'finecho.security.pin.v1';

  /// The backing secure-storage contract.
  final SecureKeyValueStore store;

  @override
  Future<bool> hasPin() async => await _readVerifier() != null;

  @override
  Future<void> savePin(String pin) {
    return store.write(credentialKey, PinVerifier.create(pin).encode());
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final verifier = await _readVerifier();
    if (verifier == null) {
      return false;
    }
    return verifier.matches(pin);
  }

  @override
  Future<void> clear() => store.delete(credentialKey);

  Future<PinVerifier?> _readVerifier() async {
    final encoded = await store.read(credentialKey);
    if (encoded == null) {
      return null;
    }
    return PinVerifier.decode(encoded);
  }
}
