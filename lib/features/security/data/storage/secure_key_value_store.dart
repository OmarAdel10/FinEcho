import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A small key-value contract over platform-backed secure storage.
abstract interface class SecureKeyValueStore {
  /// Reads the value stored under [key], or null when absent.
  Future<String?> read(String key);

  /// Writes [value] under [key].
  Future<void> write(String key, String value);

  /// Deletes the value stored under [key].
  Future<void> delete(String key);

  /// Whether the store still holds entries this build cannot read.
  ///
  /// The platform backend changed between secure-storage releases, so data
  /// written by an earlier build can become unreadable without raising an
  /// error. The store reports that state so the app can fail closed instead
  /// of reading the missing values as a fresh install.
  Future<bool> hasUnreadableLegacyData();
}

/// [SecureKeyValueStore] backed by the platform keystore.
///
/// The store uses the current secure-storage backend, which encrypts the
/// payload with AES-GCM and wraps the key with the Android keystore. The
/// legacy encrypted-shared-preferences backend is not used.
///
/// `resetOnError` is disabled on purpose. The plugin would otherwise erase
/// every stored value when the keystore reports an error, which would
/// silently remove the app lock. Failing instead lets the recovery screen
/// offer a deliberate reset.
///
/// The store also reports data written by an earlier build that the current
/// backend can no longer read. The app fails closed on that report instead of
/// treating the missing values as a fresh install.
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  /// Creates a store using the platform secure-storage implementation.
  const new({
    this.storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: false),
    ),
  });

  /// The platform secure-storage implementation.
  final FlutterSecureStorage storage;

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) => storage.delete(key: key);

  @override
  Future<bool> hasUnreadableLegacyData() async {
    try {
      final status = await storage.checkUpgradeStatus();
      return status.state == SecureStorageUpgradeState.legacyDataUnreadable ||
          status.state == SecureStorageUpgradeState.legacyDataDiscarded;
    } on Object {
      // The check is unavailable on some platforms. A broken store still
      // fails closed because the read itself raises an error.
      return false;
    }
  }
}
