import 'dart:convert';
import 'dart:math';

import 'package:finecho/features/security/data/storage/secure_key_value_store.dart';

/// Stores the key that encrypts FinEcho's local database.
///
/// The key is generated once from a cryptographically secure source and kept
/// in platform secure storage. It must never change: a different key makes
/// the existing database unreadable, so the stored value is always reused.
class DatabaseKeyStore {
  /// Creates a key store over [store].
  const new({required this.store});

  /// The secure-storage key that holds the database key.
  static const String keyName = 'finecho.database.key';

  /// The number of random bytes in a database key.
  static const int keyLength = 32;

  /// The secure-storage contract.
  final SecureKeyValueStore store;

  /// Returns the database key, creating it when it is missing.
  ///
  /// The key is written once and read from then on, so the database stays
  /// readable across restarts.
  Future<String> readOrCreateKey() async {
    final existing = await store.read(keyName);
    if (existing != null) {
      return existing;
    }

    final random = Random.secure();
    final created = base64UrlEncode(
      List<int>.generate(keyLength, (_) => random.nextInt(256)),
    );
    await store.write(keyName, created);
    return created;
  }
}
