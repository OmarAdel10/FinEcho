import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted HMAC-SHA256 hashing for the app-lock PIN.
abstract final class SecurityPinHasher {
  /// Creates a random 16-byte base64Url salt.
  static String createSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  /// Returns the base64Url HMAC-SHA256 hash of [pin] keyed by [salt].
  static String hash(String pin, String salt) {
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
  }) {
    final actualBytes = utf8.encode(hash(pin, salt));
    final expectedBytes = utf8.encode(expectedHash);
    if (actualBytes.length != expectedBytes.length) {
      return false;
    }

    var difference = 0;
    for (var index = 0; index < actualBytes.length; index++) {
      difference |= actualBytes[index] ^ expectedBytes[index];
    }
    return difference == 0;
  }
}
