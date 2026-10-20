import 'dart:convert';

import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';
import 'package:finecho/features/security/data/repositories/security_pin_hasher.dart';
import 'package:finecho/features/security/data/storage/secure_key_value_store.dart';

/// Persists the salted PIN verifier in platform secure storage.
class SecureStorageSecurityCredentialRepository
    implements SecurityCredentialRepository {
  /// Creates a repository over [store].
  const new({required this.store});

  /// The secure-storage key holding the salt and PIN hash.
  static const String credentialKey = 'finecho.security.pin.v1';

  /// The backing secure-storage contract.
  final SecureKeyValueStore store;

  @override
  Future<bool> hasPin() async => await _readCredential() != null;

  @override
  Future<void> savePin(String pin) {
    final salt = SecurityPinHasher.createSalt();
    final credential = <String, String>{
      'salt': salt,
      'hash': SecurityPinHasher.hash(pin, salt),
    };
    return store.write(credentialKey, jsonEncode(credential));
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final credential = await _readCredential();
    if (credential == null) {
      return false;
    }
    return SecurityPinHasher.matches(
      pin: pin,
      salt: credential.salt,
      expectedHash: credential.hash,
    );
  }

  @override
  Future<void> clear() => store.delete(credentialKey);

  Future<({String salt, String hash})?> _readCredential() async {
    final encoded = await store.read(credentialKey);
    if (encoded == null) {
      return null;
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid persisted PIN verifier.');
    }
    final salt = decoded['salt'];
    final hash = decoded['hash'];
    if (salt is! String || hash is! String) {
      throw const FormatException('Invalid persisted PIN verifier.');
    }
    return (salt: salt, hash: hash);
  }
}
