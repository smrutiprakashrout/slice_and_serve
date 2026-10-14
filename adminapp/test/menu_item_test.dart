import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/models/menu_item.dart';

void main() {
  group('MenuItem Model Tests', () {
    test('fromJson parses standard backend JSON payload correctly', () {
      final json = <String, dynamic>{
        'id': 'item-101',
        '_id': 'item-101',
        'name': 'Chicken Burger',
        'subtitle': 'Classic chicken patty',
        'price': 79,
        'categorySlug': 'burger',
        'type': 'non-veg',
        'featured': true,
        'image': '/images/burger.jpg',
        'available': true,
      };

      final item = MenuItem.fromJson(json);

      expect(item.id, 'item-101');
      expect(item.name, 'Chicken Burger');
      expect(item.subtitle, 'Classic chicken patty');
      expect(item.price, 79.0);
      expect(item.categorySlug, 'burger');
      expect(item.type, 'non-veg');
      expect(item.featured, isTrue);
      expect(item.image, '/images/burger.jpg');
      expect(item.available, isTrue);
    });

    test('fromJson falls back to _id when id is absent', () {
      final json = <String, dynamic>{
        '_id': 'mongo-oid-12345',
        'name': 'Paneer Sandwich',
        'subtitle': 'Spiced cottage cheese',
        'price': 69.5,
        'categorySlug': 'sandwitch',
        'type': 'veg',
        'featured': false,
        'available': false,
      };

      final item = MenuItem.fromJson(json);

      expect(item.id, 'mongo-oid-12345');
      expect(item.name, 'Paneer Sandwich');
      expect(item.price, 69.5);
      expect(item.categorySlug, 'sandwitch');
      expect(item.type, 'veg');
      expect(item.featured, isFalse);
      expect(item.image, isNull);
      expect(item.available, isFalse);
    });

    test('toJson produces expected API map', () {
      const item = MenuItem(
        id: 'menu-1',
        name: 'Classic Margherita',
        subtitle: 'San Marzano tomatoes & basil',
        price: 249.0,
        categorySlug: 'pizza',
        type: 'veg',
        featured: true,
        image: '/images/margherita.jpg',
        available: true,
      );

      final json = item.toJson();

      expect(json['id'], 'menu-1');
      expect(json['name'], 'Classic Margherita');
      expect(json['subtitle'], 'San Marzano tomatoes & basil');
      expect(json['price'], 249.0);
      expect(json['categorySlug'], 'pizza');
      expect(json['type'], 'veg');
      expect(json['featured'], isTrue);
      expect(json['image'], '/images/margherita.jpg');
      expect(json['available'], isTrue);
    });

    test('copyWith updates specified fields and preserves remainder', () {
      const original = MenuItem(
        id: 'test-1',
        name: 'Test Pizza',
        subtitle: 'Cheese & crust',
        price: 200.0,
        categorySlug: 'pizza',
        type: 'veg',
        featured: false,
        image: null,
        available: true,
      );

      final updated = original.copyWith(
        available: false,
        featured: true,
        price: 250.0,
      );

      expect(updated.id, 'test-1');
      expect(updated.name, 'Test Pizza');
      expect(updated.available, isFalse);
      expect(updated.featured, isTrue);
      expect(updated.price, 250.0);
      expect(updated.type, 'veg');
    });

    test('operator == and hashCode are based on id', () {
      const itemA = MenuItem(
        id: 'same-id',
        name: 'Name A',
        subtitle: 'Sub A',
        price: 100,
        categorySlug: 'pizza',
        type: 'veg',
      );
      const itemB = MenuItem(
        id: 'same-id',
        name: 'Name B',
        subtitle: 'Sub B',
        price: 200,
        categorySlug: 'burger',
        type: 'non-veg',
      );

      expect(itemA, equals(itemB));
      expect(itemA.hashCode, equals(itemB.hashCode));
    });
  });
}
