import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/core/api_client.dart';
import 'package:adminapp/core/result.dart';
import 'package:adminapp/core/secure_store.dart';
import 'package:adminapp/models/category.dart';
import 'package:adminapp/models/menu_item.dart';
import 'package:adminapp/services/menu_service.dart';

void main() {
  late SecureStore secureStore;

  setUp(() {
    secureStore = SecureStore();
  });

  group('MenuService Tests (Task 2B-1)', () {
    test('getMenuItems parses { categories, items } envelope successfully',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'categories': [
                    {'id': 'cat-1', 'name': 'Burger', 'slug': 'burger'},
                  ],
                  'items': [
                    {
                      'id': 'item-1',
                      'name': 'Chicken Burger',
                      'subtitle': 'Classic chicken patty',
                      'price': 79,
                      'categorySlug': 'burger',
                      'type': 'non-veg',
                      'featured': true,
                      'image': '/images/burger.jpg',
                      'available': true,
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.getMenuItems();

      expect(result.isSuccess, isTrue);
      final items = (result as Success).data;
      expect(items.length, 1);
      expect(items.first.id, 'item-1');
      expect(items.first.name, 'Chicken Burger');
      expect(items.first.price, 79.0);
      expect(items.first.featured, isTrue);
      expect(items.first.available, isTrue);
    });

    test('getMenuItems parses direct List envelope successfully', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: [
                  {
                    'id': 'item-2',
                    'name': 'Veggie Pizza',
                    'subtitle': 'Fresh veggies and cheese',
                    'price': 199,
                    'categorySlug': 'pizza',
                    'type': 'veg',
                    'featured': false,
                    'available': true,
                  },
                ],
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.getMenuItems();

      expect(result.isSuccess, isTrue);
      final items = (result as Success).data;
      expect(items.length, 1);
      expect(items.first.id, 'item-2');
      expect(items.first.name, 'Veggie Pizza');
    });

    test('getMenuItems handles backend DioException with error envelope',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 500,
                  data: {
                    'error': {
                      'code': 'SERVER_ERROR',
                      'message': 'Database connection failed.',
                    },
                  },
                ),
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.getMenuItems();

      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.errorMessage, 'Database connection failed.');
      expect(failure.statusCode, 500);
      expect(failure.errorCode, 'SERVER_ERROR');
    });

    test('getMenuItems returns failure for invalid data format', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: 'Not a JSON map or list',
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.getMenuItems();

      expect(result.isFailure, isTrue);
      expect((result as Failure).errorMessage,
          'Invalid menu data format from server.');
    });

    test('setAvailability PATCHes /api/menu/:id/availability successfully',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'PATCH');
            expect(options.path, '/api/menu/item-1/availability');
            expect(options.data, {'available': false});
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'item-1',
                  'name': 'Chicken Burger',
                  'subtitle': 'Classic chicken patty',
                  'price': 79,
                  'categorySlug': 'burger',
                  'type': 'non-veg',
                  'featured': true,
                  'available': false,
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.setAvailability('item-1', false);

      expect(result.isSuccess, isTrue);
      final updated = (result as Success).data;
      expect(updated.id, 'item-1');
      expect(updated.available, isFalse);
    });

    test('setAvailability handles backend failure with error message',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  data: {
                    'error': {
                      'code': 'NOT_FOUND',
                      'message': "Menu item with id 'item-99' not found.",
                    },
                  },
                ),
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.setAvailability('item-99', true);

      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.errorMessage,
          "Menu item with id 'item-99' not found.");
      expect(failure.statusCode, 404);
      expect(failure.errorCode, 'NOT_FOUND');
    });

    test(
        'createMenuItem POSTs /api/menu with valid payload and returns created item',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'POST');
            expect(options.path, '/api/menu');
            final data = options.data as Map<String, dynamic>;
            expect(data['name'], 'Truffle Fries');
            expect(data['price'], 149.0);
            expect(data['categorySlug'], 'sides');
            expect(data['type'], 'veg');
            expect(data['image'], isNotEmpty);
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'id': 'new-item-123',
                  'name': 'Truffle Fries',
                  'subtitle': 'Golden crisp truffle fries',
                  'price': 149,
                  'categorySlug': 'sides',
                  'type': 'veg',
                  'featured': false,
                  'available': true,
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      const newItem = MenuItem(
        id: '',
        name: 'Truffle Fries',
        subtitle: 'Golden crisp truffle fries',
        price: 149.0,
        categorySlug: 'sides',
        type: 'veg',
      );

      final result = await service.createMenuItem(newItem);
      expect(result.isSuccess, isTrue);
      final created = (result as Success).data;
      expect(created.id, 'new-item-123');
      expect(created.name, 'Truffle Fries');
    });

    test('createMenuItem handles 400 validation error envelope', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 400,
                  data: {
                    'error': {
                      'code': 'VALIDATION_ERROR',
                      'message': "Category with slug 'invalid' does not exist.",
                    },
                  },
                ),
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      const newItem = MenuItem(
        id: '',
        name: 'Invalid Item',
        subtitle: 'Invalid category item',
        price: 99.0,
        categorySlug: 'invalid',
        type: 'veg',
      );

      final result = await service.createMenuItem(newItem);
      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.errorMessage,
          "Category with slug 'invalid' does not exist.");
      expect(failure.statusCode, 400);
      expect(failure.errorCode, 'VALIDATION_ERROR');
    });

    test('updateMenuItem PUTs /api/menu/:id and returns updated item',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'PUT');
            expect(options.path, '/api/menu/item-1');
            final data = options.data as Map<String, dynamic>;
            expect(data['name'], 'Updated Burger');
            expect(data['price'], 129.0);
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'item-1',
                  'name': 'Updated Burger',
                  'subtitle': 'Updated subtitle',
                  'price': 129,
                  'categorySlug': 'burger',
                  'type': 'non-veg',
                  'featured': true,
                  'available': true,
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      const updatedItem = MenuItem(
        id: 'item-1',
        name: 'Updated Burger',
        subtitle: 'Updated subtitle',
        price: 129.0,
        categorySlug: 'burger',
        type: 'non-veg',
        featured: true,
      );

      final result = await service.updateMenuItem('item-1', updatedItem);
      expect(result.isSuccess, isTrue);
      final updated = (result as Success).data;
      expect(updated.id, 'item-1');
      expect(updated.price, 129.0);
    });

    test('deleteMenuItem sends DELETE /api/menu/:id and returns success',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'DELETE');
            expect(options.path, '/api/menu/item-to-delete');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'deleted': true, 'id': 'item-to-delete'},
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.deleteMenuItem('item-to-delete');
      expect(result.isSuccess, isTrue);
    });

    test('deleteMenuItem returns failure on 404', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  data: {
                    'error': {
                      'code': 'NOT_FOUND',
                      'message': "Menu item with id 'invalid-id' not found.",
                    },
                  },
                ),
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.deleteMenuItem('invalid-id');
      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.errorMessage,
          "Menu item with id 'invalid-id' not found.");
      expect(failure.statusCode, 404);
      expect(failure.errorCode, 'NOT_FOUND');
    });

    test('getCategories parses standard list of categories successfully',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: [
                  {
                    'id': 'cat-1',
                    '_id': 'cat-1',
                    'name': 'Sandwitch',
                    'slug': 'sandwitch',
                    'icon': '🥪',
                    'sortOrder': 1,
                  },
                  {
                    'id': 'cat-2',
                    '_id': 'cat-2',
                    'name': 'Burger',
                    'slug': 'burger',
                    'icon': '🍔',
                    'sortOrder': 2,
                  },
                ],
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.getCategories();
      expect(result.isSuccess, isTrue);
      final categories = (result as Success<List<Category>>).data;
      expect(categories.length, 2);
      expect(categories[0].name, 'Sandwitch');
      expect(categories[0].slug, 'sandwitch');
      expect(categories[0].icon, '🥪');
      expect(categories[1].name, 'Burger');
      expect(categories[1].slug, 'burger');
      expect(categories[1].icon, '🍔');
    });

    test('getCategories parses wrapped { categories: [...] } format',
        () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'categories': [
                    {
                      'id': 'cat-1',
                      'name': 'Drinks',
                      'slug': 'drinks',
                      'icon': '🥤',
                      'sortOrder': 4,
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.getCategories();
      expect(result.isSuccess, isTrue);
      final categories = (result as Success<List<Category>>).data;
      expect(categories.length, 1);
      expect(categories.first.name, 'Drinks');
      expect(categories.first.slug, 'drinks');
    });

    test('getCategories returns failure on DioException error', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 500,
                  data: {
                    'error': {
                      'code': 'INTERNAL_ERROR',
                      'message': 'Database connection error.',
                    },
                  },
                ),
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = MenuService(apiClient: client);

      final result = await service.getCategories();
      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.errorMessage, 'Database connection error.');
      expect(failure.statusCode, 500);
    });
  });
}
