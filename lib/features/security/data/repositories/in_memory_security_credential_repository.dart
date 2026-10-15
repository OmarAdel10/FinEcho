import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:finecho/features/security/data/repositories/security_credential_repository.dart';

/// An in-memory salted-hash store used until secure platform storage is wired.
class InMemorySecurityCredentialRepository
    implements SecurityCredentialRepository {
  String? _salt;
  String? _pinHash;

  @override
  Future<bool> hasPin() async => _pinHash != null;

  @override
  Future<void> savePin(String pin) async {
    final salt = _createSalt();
    _salt = salt;
    _pinHash = _hash(pin, salt);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final salt = _salt;
    final pinHash = _pinHash;
    if (salt == null || pinHash == null) {
      return false;
    }
    return _hash(pin, salt) == pinHash;
  }

  @override
  Future<void> clear() async {
    _salt = null;
    _pinHash = null;
  }

  String _createSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  String _hash(String pin, String salt) {
    return base64UrlEncode(
      Hmac(sha256, utf8.encode(salt)).convert(utf8.encode(pin)).bytes,
    );
  }
}
