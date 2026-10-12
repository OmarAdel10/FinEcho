import 'package:flutter/foundation.dart';

/// A user-facing grouping for transactions and budgets.
@immutable
class Category {
  /// Creates an immutable category snapshot.
  const new({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    this.parentId,
  });

  /// Creates a category from a SQLite row map.
  factory fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id']! as String,
      parentId: map['parent_id'] as String?,
      name: map['name']! as String,
      iconKey: map['icon_key']! as String,
      colorHex: map['color_hex']! as String,
    );
  }

  /// The stable local identifier for the category.
  final String id;

  /// The identifier of the parent category, if this category is nested.
  final String? parentId;

  /// The display name of the category.
  final String name;

  /// The stable icon key used by the presentation layer.
  final String iconKey;

  /// The category color as a hexadecimal string.
  final String colorHex;

  /// Returns a copy with non-null fields replaced by the supplied values.
  Category copyWith({
    String? id,
    String? parentId,
    String? name,
    String? iconKey,
    String? colorHex,
  }) {
    return Category(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  /// Converts the category to a map for SQLite persistence.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'parent_id': parentId,
      'name': name,
      'icon_key': iconKey,
      'color_hex': colorHex,
    };
  }

  /// Whether [other] is a category with the same field values.
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Category &&
            id == other.id &&
            parentId == other.parentId &&
            name == other.name &&
            iconKey == other.iconKey &&
            colorHex == other.colorHex;
  }

  /// A hash code derived from every category field.
  @override
  int get hashCode => Object.hash(id, parentId, name, iconKey, colorHex);
}
