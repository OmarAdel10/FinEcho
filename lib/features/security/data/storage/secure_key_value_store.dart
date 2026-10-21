import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A small key-value contract over platform-backed secure storage.
abstract interface class SecureKeyValueStore {
  /// Reads the value stored under [key], or null when absent.
  Future<String?> read(String key);

  /// Writes [value] under [key].
  Future<void> write(String key, String value);

  /// Deletes the value stored under [key].
  Future<void> delete(String key);
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
}
