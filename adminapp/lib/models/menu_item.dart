import 'package:flutter/foundation.dart';

/// Immutable model representing a menu item in Slice & Serve.
///
/// Matches `ARCHITECTURE.md` §3 specification:
/// - [id]: Unique identifier string
/// - [name]: Display title
/// - [subtitle]: Short description/ingredients
/// - [price]: Price in shop currency
/// - [categorySlug]: Category identifier (e.g. "pizza", "burger")
/// - [type]: "veg" or "non-veg"
/// - [featured]: Highlighted in customer promotions
/// - [image]: Nullable image URL; always null in Stage A per PRD A-16
/// - [available]: Availability status toggle for kitchen dispatch
@immutable
class MenuItem {
  final String id;
  final String name;
  final String subtitle;
  final double price;
  final String categorySlug;
  final String type; // "veg" | "non-veg"
  final bool featured;
  final String? image; // Nullable; permanent placeholder used when null (PRD A-16)
  final bool available;

  const MenuItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.categorySlug,
    required this.type,
    this.featured = false,
    this.image,
    this.available = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      categorySlug: json['categorySlug'] as String? ?? '',
      type: json['type'] as String? ?? 'veg',
      featured: json['featured'] as bool? ?? false,
      image: json['image'] as String?,
      available: json['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'price': price,
      'categorySlug': categorySlug,
      'type': type,
      'featured': featured,
      'image': image,
      'available': available,
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? subtitle,
    double? price,
    String? categorySlug,
    String? type,
    bool? featured,
    String? image,
    bool? available,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      price: price ?? this.price,
      categorySlug: categorySlug ?? this.categorySlug,
      type: type ?? this.type,
      featured: featured ?? this.featured,
      image: image ?? this.image,
      available: available ?? this.available,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'MenuItem(id: $id, name: $name, price: $price, available: $available)';
}
