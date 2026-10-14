import 'package:flutter/foundation.dart';

/// Category model representing a menu classification item in Slice & Serve.
///
/// Corresponds to the schema returned by `GET /api/categories`:
/// - [id]: Unique identifier string (or `_id` from MongoDB)
/// - [name]: Human-readable category display title (e.g. "Burger", "Sandwitch")
/// - [slug]: URL/identifier key (e.g. "burger", "sandwitch")
/// - [icon]: Optional emoji or icon indicator (e.g. "🍔", "🥪")
/// - [sortOrder]: Display ordering integer (1-indexed ascending)
@immutable
class Category {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.sortOrder = 0,
  });

  /// Factory constructor to parse a [Category] from API JSON.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      slug: (json['slug'] as String?)?.trim() ?? '',
      icon: (json['icon'] as String?)?.trim(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  /// Serializes this [Category] instance into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (icon != null) 'icon': icon,
      'sortOrder': sortOrder,
    };
  }

  /// Returns a copy of this [Category] with updated fields.
  Category copyWith({
    String? id,
    String? name,
    String? slug,
    String? icon,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          slug == other.slug &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, slug, name);

  @override
  String toString() =>
      'Category(id: $id, name: $name, slug: $slug, icon: $icon, sortOrder: $sortOrder)';
}
