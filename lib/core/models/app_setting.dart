import 'package:flutter/foundation.dart';

/// A string-valued user preference stored by FinEcho.
@immutable
class AppSetting {
  /// Creates an immutable app setting.
  const new({required this.key, required this.value, required this.updatedAt});

  /// Creates an app setting from a SQLite row map.
  factory fromMap(Map<String, Object?> map) {
    return AppSetting(
      key: map['key']! as String,
      value: map['value']! as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updated_at']! as int,
        isUtc: true,
      ),
    );
  }

  /// The stable preference key.
  final String key;

  /// The preference value.
  final String value;

  /// The UTC time at which the setting was last written.
  final DateTime updatedAt;

  /// Returns a copy with non-null fields replaced by the supplied values.
  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) {
    return AppSetting(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts the setting to a map for SQLite persistence.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'key': key,
      'value': value,
      'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
    };
  }

  /// Whether [other] is an app setting with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppSetting &&
            key == other.key &&
            value == other.value &&
            updatedAt == other.updatedAt;
  }

  /// A hash code derived from every app-setting field.
  @override
  int get hashCode => Object.hash(key, value, updatedAt);
}
