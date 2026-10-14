import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/models/category.dart';

void main() {
  group('Category Model Tests (Task 2B-5)', () {
    test('fromJson parses standard MongoDB /api/categories object', () {
      final json = {
        'id': '6aaa25625a5c1215a384ba16',
        '_id': '6aaa25625a5c1215a384ba16',
        'name': 'Burger',
        'slug': 'burger',
        'icon': '🍔',
        'sortOrder': 2,
      };

      final category = Category.fromJson(json);

      expect(category.id, '6aaa25625a5c1215a384ba16');
      expect(category.name, 'Burger');
      expect(category.slug, 'burger');
      expect(category.icon, '🍔');
      expect(category.sortOrder, 2);
    });

    test('fromJson falls back to _id if id is absent', () {
      final json = {
        '_id': '6aaa25625a5c1215a384ba15',
        'name': 'Sandwitch',
        'slug': 'sandwitch',
        'icon': '🥪',
        'sortOrder': 1,
      };

      final category = Category.fromJson(json);

      expect(category.id, '6aaa25625a5c1215a384ba15');
      expect(category.name, 'Sandwitch');
      expect(category.slug, 'sandwitch');
      expect(category.icon, '🥪');
      expect(category.sortOrder, 1);
    });

    test('fromJson handles null icon and default sortOrder safely', () {
      final json = {
        'id': 'cat-minimal',
        'name': 'Drinks',
        'slug': 'drinks',
      };

      final category = Category.fromJson(json);

      expect(category.id, 'cat-minimal');
      expect(category.name, 'Drinks');
      expect(category.slug, 'drinks');
      expect(category.icon, isNull);
      expect(category.sortOrder, 0);
    });

    test('toJson serializes correctly', () {
      const category = Category(
        id: 'cat-1',
        name: 'Sides & Starters',
        slug: 'staters',
        icon: '🍟',
        sortOrder: 3,
      );

      final json = category.toJson();

      expect(json['id'], 'cat-1');
      expect(json['name'], 'Sides & Starters');
      expect(json['slug'], 'staters');
      expect(json['icon'], '🍟');
      expect(json['sortOrder'], 3);
    });

    test('copyWith updates fields while preserving others', () {
      const original = Category(
        id: 'cat-1',
        name: 'Drinks',
        slug: 'drinks',
        icon: '🥤',
        sortOrder: 4,
      );

      final updated = original.copyWith(name: 'Cold Drinks', sortOrder: 5);

      expect(updated.id, 'cat-1');
      expect(updated.name, 'Cold Drinks');
      expect(updated.slug, 'drinks');
      expect(updated.icon, '🥤');
      expect(updated.sortOrder, 5);
    });

    test('equality and hashCode work as expected', () {
      const cat1 = Category(
        id: 'cat-1',
        name: 'Pizza',
        slug: 'pizza',
      );
      const cat2 = Category(
        id: 'cat-1',
        name: 'Pizza',
        slug: 'pizza',
      );
      const cat3 = Category(
        id: 'cat-2',
        name: 'Burger',
        slug: 'burger',
      );

      expect(cat1, equals(cat2));
      expect(cat1.hashCode, equals(cat2.hashCode));
      expect(cat1, isNot(equals(cat3)));
    });
  });
}
