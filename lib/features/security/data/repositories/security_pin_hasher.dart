import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Key derivation for the app-lock PIN verifier.
abstract final class SecurityPinHasher {
  /// The number of derivation rounds used for new verifiers.
  ///
  /// A six-digit PIN has only one million possible values, so the derivation
  /// cost is what keeps an offline attacker from brute-forcing the verifier
  /// that is persisted in secure storage.
  static const int defaultIterations = 100000;

  /// The number of bytes in a stored salt.
  static const int saltLength = 16;

  /// The number of bytes in a stored verifier.
  static const int hashLength = 32;

  /// Creates a random 16-byte base64Url salt.
  static String createSalt() {
    final random = Random.secure();
    return base64UrlEncode(
      List<int>.generate(saltLength, (_) => random.nextInt(256)),
    );
  }

  /// Whether [encoded] is base64Url data of exactly [length] bytes.
  ///
  /// A persisted verifier that does not have the expected shape can never
  /// match, so it is rejected instead of locking the user out of the app.
  static bool hasByteLength(String encoded, int length) {
    try {
      return base64Url.decode(encoded).length == length;
    } on FormatException {
      return false;
    }
  }

  /// Derives the base64Url PBKDF2-HMAC-SHA256 verifier of [pin].
  ///
  /// [iterations] is stored with the verifier so the cost can be raised
  /// without invalidating verifiers that are already persisted.
  static String hash(
    String pin,
    String salt, {
    int iterations = defaultIterations,
  }) {
    return base64UrlEncode(
      _derive(
        password: utf8.encode(pin),
        salt: utf8.encode(salt),
        iterations: iterations,
      ),
    );
  }

  /// Derives the base64Url HMAC-SHA256 verifier of [pin] used by format v1.
  ///
  /// Kept only to verify verifiers that were persisted before the key
  /// derivation was hardened.
  static String legacyHash(String pin, String salt) {
    return base64UrlEncode(
      Hmac(sha256, utf8.encode(salt)).convert(utf8.encode(pin)).bytes,
    );
  }

  /// Whether [pin] produces [expectedHash] for [salt].
  ///
  /// The comparison length is independent of the first differing byte.
  static bool matches({
    required String pin,
    required String salt,
    required String expectedHash,
    int iterations = defaultIterations,
  }) {
    return _constantTimeEquals(
      hash(pin, salt, iterations: iterations),
      expectedHash,
    );
  }

  /// Whether [pin] produces the legacy [expectedHash] for [salt].
  static bool matchesLegacy({
    required String pin,
    required String salt,
    required String expectedHash,
  }) {
    return _constantTimeEquals(legacyHash(pin, salt), expectedHash);
  }

  /// Derives the verifier of [pin] on a background isolate.
  ///
  /// The derivation is deliberately expensive, so it must not run on the
  /// platform isolate where it would freeze the interface while the user
  /// waits for the app lock to be set up or unlocked.
  static Future<String> hashInBackground(
    String pin,
    String salt, {
    int iterations = defaultIterations,
  }) {
    return compute(_deriveVerifier, (
      pin: pin,
      salt: salt,
      iterations: iterations,
    ), debugLabel: 'app lock PIN derivation');
  }

  /// Whether [pin] produces [expectedHash] for [salt] on a background
  /// isolate.
  static Future<bool> matchesInBackground({
    required String pin,
    required String salt,
    required String expectedHash,
    int iterations = defaultIterations,
  }) {
    return compute(_verifyVerifier, (
      pin: pin,
      salt: salt,
      expectedHash: expectedHash,
      iterations: iterations,
    ), debugLabel: 'app lock PIN verification');
  }

  static bool _constantTimeEquals(String actual, String expected) {
    final actualBytes = utf8.encode(actual);
    final expectedBytes = utf8.encode(expected);
    if (actualBytes.length != expectedBytes.length) {
      return false;
    }

    var difference = 0;
    for (var index = 0; index < actualBytes.length; index++) {
      difference |= actualBytes[index] ^ expectedBytes[index];
    }
    return difference == 0;
  }

  static Uint8List _derive({
    required List<int> password,
    required List<int> salt,
    required int iterations,
  }) {
    final hmac = Hmac(sha256, password);
    final seed = Uint8List.fromList([...salt, 0, 0, 0, 1]);
    var block = Uint8List.fromList(hmac.convert(seed).bytes);
    final derived = Uint8List.fromList(block);
    for (var round = 1; round < iterations; round++) {
      block = Uint8List.fromList(hmac.convert(block).bytes);
      for (var index = 0; index < derived.length; index++) {
        derived[index] ^= block[index];
      }
    }
    return derived;
  }
}

/// The work sent to the background isolate that derives a verifier.
typedef _DerivationInput = ({String pin, String salt, int iterations});

/// The work sent to the background isolate that verifies a PIN.
typedef _VerificationInput = ({
  String pin,
  String salt,
  String expectedHash,
  int iterations,
});

/// Derives a verifier on the background isolate.
///
/// The entry point must stay a top-level function so it can be sent to the
/// isolate.
String _deriveVerifier(_DerivationInput input) {
  return SecurityPinHasher.hash(
    input.pin,
    input.salt,
    iterations: input.iterations,
  );
}

/// Verifies a PIN on the background isolate.
///
/// The entry point must stay a top-level function so it can be sent to the
/// isolate.
bool _verifyVerifier(_VerificationInput input) {
  return SecurityPinHasher.matches(
    pin: input.pin,
    salt: input.salt,
    expectedHash: input.expectedHash,
    iterations: input.iterations,
  );
}
