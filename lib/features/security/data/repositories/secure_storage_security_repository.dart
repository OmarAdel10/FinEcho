import 'dart:convert';

import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/features/security/data/storage/secure_key_value_store.dart';

/// Persists non-secret app-lock metadata in platform secure storage.
class SecureStorageSecurityRepository implements SecurityRepository {
  /// Creates a repository over [store].
  const new({required this.store});

  /// The secure-storage key holding the serialized security state.
  static const String stateKey = 'finecho.security.state.v1';

  /// The backing secure-storage contract.
  final SecureKeyValueStore store;

  @override
  Future<SecurityState?> get() async {
    final encoded = await store.read(stateKey);
    if (encoded == null) {
      return null;
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid persisted security state.');
    }
    return SecurityState.fromMap(Map<String, Object?>.from(decoded));
  }

  @override
  Future<void> update(SecurityState state) {
    return store.write(stateKey, jsonEncode(state.toMap()));
  }
}
