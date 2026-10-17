import 'package:adminapp/core/menu_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveMenuImageUrl', () {
    test('returns null for null, empty, and whitespace-only values', () {
      expect(resolveMenuImageUrl(null), isNull);
      expect(resolveMenuImageUrl(''), isNull);
      expect(resolveMenuImageUrl('   \t\n'), isNull);
    });

    test('treats the saved placeholder path as missing', () {
      expect(resolveMenuImageUrl('/images/placeholder.jpg'), isNull);
      expect(resolveMenuImageUrl('images/placeholder.jpg'), isNull);
      expect(resolveMenuImageUrl('/IMAGES/PLACEHOLDER.JPG'), isNull);
    });

    test('returns an absolute HTTPS URL trimmed as-is', () {
      const url = 'https://cdn.example.com/dish.jpg?width=400';
      expect(resolveMenuImageUrl('  $url  '), url);
    });

    test('resolves paths with and without a leading slash', () {
      expect(
        resolveMenuImageUrl('/images/burger.jpg'),
        'https://sliceandserve.vercel.app/images/burger.jpg',
      );
      expect(
        resolveMenuImageUrl('images/burger.jpg'),
        'https://sliceandserve.vercel.app/images/burger.jpg',
      );
    });

    test('URL-encodes spaces without double-encoding existing escapes', () {
      expect(
        resolveMenuImageUrl('/images/cold coffee.jpg'),
        'https://sliceandserve.vercel.app/images/cold%20coffee.jpg',
      );
      expect(
        resolveMenuImageUrl('/images/cold%20coffee.jpg'),
        'https://sliceandserve.vercel.app/images/cold%20coffee.jpg',
      );
    });

    test('removes trailing slashes from the supplied base URL', () {
      expect(
        resolveMenuImageUrl(
          '/images/burger.jpg',
          baseUrl: 'https://cdn.example.com/menu///',
        ),
        'https://cdn.example.com/menu/images/burger.jpg',
      );
    });

    test('preserves nested image folders', () {
      expect(
        resolveMenuImageUrl('/images/drink/cold_coffee.jpg'),
        'https://sliceandserve.vercel.app/images/drink/cold_coffee.jpg',
      );
    });
  });
}
