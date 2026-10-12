import 'package:flutter/foundation.dart';

/// Non-secret security metadata for the FinEcho app lock.
@immutable
class SecurityState {
  /// Creates immutable, non-secret security state.
  const new({
    required this.appLockEnabled,
    required this.pinConfigured,
    required this.failedUnlockAttempts,
    required this.secureKeyReady,
    required this.updatedAt,
    this.lockedUntil,
  });

  /// Creates security state from the singleton SQLite row map.
  factory fromMap(Map<String, Object?> map) {
    final id = map['id']! as int;
    if (id != singletonId) {
      throw ArgumentError.value(id, 'id', 'Security state must use id 0.');
    }

    return SecurityState(
      appLockEnabled: map['app_lock_enabled']! as int == 1,
      pinConfigured: map['pin_configured']! as int == 1,
      failedUnlockAttempts: map['failed_unlock_attempts']! as int,
      lockedUntil: map['locked_until'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              map['locked_until']! as int,
              isUtc: true,
            ),
      secureKeyReady: map['secure_key_ready']! as int == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at']! as int,
        isUtc: true,
      ),
    );
  }

  /// The database row id reserved for the singleton security state.
  static const int singletonId = 0;

  /// Whether the app lock is enabled.
  final bool appLockEnabled;

  /// Whether a PIN has been configured.
  final bool pinConfigured;

  /// The number of consecutive failed unlock attempts.
  final int failedUnlockAttempts;

  /// The UTC time until which the app remains locked, if locked.
  final DateTime? lockedUntil;

  /// Whether the platform secure key has been initialized and is readable.
  final bool secureKeyReady;

  /// The UTC time at which this security state was last written.
  final DateTime updatedAt;

  /// Returns a copy with non-null fields replaced by the supplied values.
  ///
  /// Pass [clearLockedUntil] as true to remove the temporary lock time.
  SecurityState copyWith({
    bool? appLockEnabled,
    bool? pinConfigured,
    int? failedUnlockAttempts,
    DateTime? lockedUntil,
    bool? secureKeyReady,
    DateTime? updatedAt,
    bool clearLockedUntil = false,
  }) {
    return SecurityState(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      pinConfigured: pinConfigured ?? this.pinConfigured,
      failedUnlockAttempts: failedUnlockAttempts ?? this.failedUnlockAttempts,
      lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
      secureKeyReady: secureKeyReady ?? this.secureKeyReady,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts the security state to a map for SQLite persistence.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': singletonId,
      'app_lock_enabled': appLockEnabled ? 1 : 0,
      'pin_configured': pinConfigured ? 1 : 0,
      'failed_unlock_attempts': failedUnlockAttempts,
      'locked_until': lockedUntil?.toUtc().millisecondsSinceEpoch,
      'secure_key_ready': secureKeyReady ? 1 : 0,
      'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  /// Whether [other] is security state with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SecurityState &&
            appLockEnabled == other.appLockEnabled &&
            pinConfigured == other.pinConfigured &&
            failedUnlockAttempts == other.failedUnlockAttempts &&
            lockedUntil == other.lockedUntil &&
            secureKeyReady == other.secureKeyReady &&
            updatedAt == other.updatedAt;
  }

  /// A hash code derived from every security-state field.
  @override
  int get hashCode => Object.hash(
    appLockEnabled,
    pinConfigured,
    failedUnlockAttempts,
    lockedUntil,
    secureKeyReady,
    updatedAt,
  );
}
