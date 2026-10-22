import 'dart:convert';

import 'package:finecho/core/models/security_state.dart';
import 'package:finecho/core/repositories/contracts/security_repository.dart';
import 'package:finecho/features/security/data/storage/secure_key_value_store.dart';

/// Persists non-secret app-lock metadata in platform secure storage.
///
/// The payload is versioned so a future format change is detected instead of
/// being silently misread. A payload written before the codec was versioned
/// is still read as the state map it carries. Every payload is validated
/// before it is decoded, so a corrupt entry fails with a
/// [FormatException] instead of a raw type error.
class SecureStorageSecurityRepository implements SecurityRepository {
  /// Creates a repository over [store].
  const new({required this.store});

  /// The secure-storage key holding the serialized security state.
  static const String stateKey = 'finecho.security.state.v1';

  /// The payload format version written by the current build.
  static const int codecVersion = 1;

  /// The state map fields that have to be stored as integers.
  static const List<String> _requiredIntKeys = [
    'id',
    'app_lock_enabled',
    'pin_configured',
    'failed_unlock_attempts',
    'secure_key_ready',
    'updated_at',
  ];

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
    if (!decoded.containsKey('version')) {
      return _stateFromMap(Map<String, Object?>.from(decoded));
    }
    if (decoded['version'] != codecVersion) {
      throw const FormatException('Unsupported persisted security state.');
    }
    final state = decoded['state'];
    if (state is! Map<String, dynamic>) {
      throw const FormatException('Invalid persisted security state.');
    }
    return _stateFromMap(Map<String, Object?>.from(state));
  }

  @override
  Future<void> update(SecurityState state) {
    return store.write(
      stateKey,
      jsonEncode({'version': codecVersion, 'state': state.toMap()}),
    );
  }

  /// Decodes a persisted state map, rejecting a payload that is not one.
  ///
  /// A corrupt payload has to fail with a [FormatException] so the recovery
  /// screen can offer a reset instead of surfacing a raw type error.
  SecurityState _stateFromMap(Map<String, Object?> map) {
    for (final key in _requiredIntKeys) {
      if (map[key] is! int) {
        throw const FormatException('Invalid persisted security state.');
      }
    }
    final lockedUntil = map['locked_until'];
    if (lockedUntil != null && lockedUntil is! int) {
      throw const FormatException('Invalid persisted security state.');
    }
    try {
      return SecurityState.fromMap(map);
    } on Object {
      throw const FormatException('Invalid persisted security state.');
    }
  }
}
