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
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  /// Creates a store using the platform secure-storage implementation.
  const new({this.storage = const FlutterSecureStorage()});

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
