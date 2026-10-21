import 'dart:convert';

import 'package:finecho/features/security/data/repositories/security_pin_hasher.dart';

/// A persisted PIN verifier with the parameters used to derive it.
class PinVerifier {
  /// Creates a verifier.
  const new({
    required this.salt,
    required this.hash,
    this.iterations = 1,
    this.version = 1,
  });

  /// Decodes a persisted verifier payload.
  ///
  /// Throws a [FormatException] when the payload is not a verifier. A corrupt
  /// payload must fail loudly so the recovery screen can offer a reset
  /// instead of leaving the user locked out of a verifier that never
  /// matches.
  factory decode(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid persisted PIN verifier.');
    }
    final salt = decoded['salt'];
    final hash = decoded['hash'];
    if (salt is! String || hash is! String) {
      throw const FormatException('Invalid persisted PIN verifier.');
    }
    if (salt.isEmpty || hash.isEmpty) {
      throw const FormatException('Invalid persisted PIN verifier.');
    }
    final version = decoded['version'];
    if (version != null && version is! int) {
      throw const FormatException('Invalid persisted PIN verifier.');
    }
    final iterations = decoded['iterations'];
    if (iterations != null && iterations is! int) {
      throw const FormatException('Invalid persisted PIN verifier.');
    }
    final resolvedVersion = version is int ? version : legacyVersion;
    final resolvedIterations = iterations is int ? iterations : 1;
    if (resolvedVersion < 1 || resolvedVersion > currentVersion) {
      throw const FormatException('Unsupported persisted PIN verifier.');
    }
    if (resolvedIterations < 1) {
      throw const FormatException('Invalid persisted PIN verifier.');
    }
    return PinVerifier(
      salt: salt,
      hash: hash,
      version: resolvedVersion,
      iterations: resolvedIterations,
    );
  }

  /// Derives a verifier for [pin] with a fresh random salt.
  factory create(String pin) {
    final salt = SecurityPinHasher.createSalt();
    return PinVerifier(
      salt: salt,
      hash: SecurityPinHasher.hash(pin, salt),
      iterations: SecurityPinHasher.defaultIterations,
      version: currentVersion,
    );
  }

  /// The payload format version written by the current build.
  static const int currentVersion = 2;

  /// The payload format version written before the derivation was hardened.
  static const int legacyVersion = 1;

  /// The random salt mixed into the derivation.
  final String salt;

  /// The derived verifier.
  final String hash;

  /// The number of derivation rounds used to produce [hash].
  final int iterations;

  /// The payload format version.
  final int version;

  /// Encodes this verifier for persistence.
  String encode() {
    return jsonEncode({
      'version': version,
      'salt': salt,
      'hash': hash,
      'iterations': iterations,
    });
  }

  /// Whether [pin] matches this verifier.
  ///
  /// Verifiers written before the derivation was hardened are verified with
  /// the legacy single-round derivation.
  bool matches(String pin) {
    if (version >= currentVersion) {
      return SecurityPinHasher.matches(
        pin: pin,
        salt: salt,
        expectedHash: hash,
        iterations: iterations,
      );
    }
    return SecurityPinHasher.matchesLegacy(
      pin: pin,
      salt: salt,
      expectedHash: hash,
    );
  }
}
