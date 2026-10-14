import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/result.dart';
import '../models/category.dart';
import '../models/menu_item.dart';

/// Service responsible for fetching and updating menu items against the backend API.
///
/// Implements `ARCHITECTURE.md` §4 (`GET /api/menu`), `CODING_STANDARDS.md` §1,
/// and `TASKS.md` Phase 2B (2B-1).
class MenuService {
  final ApiClient _apiClient;

  MenuService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches the catalog of menu items via `GET /api/menu`.
  ///
  /// Response payload shape:
  /// ```json
  /// {
  ///   "categories": [ ... ],
  ///   "items": [
  ///     {
  ///       "id": "...",
  ///       "name": "Chicken Burger",
  ///       "subtitle": "Classic chicken patty",
  ///       "price": 79,
  ///       "categorySlug": "burger",
  ///       "type": "non-veg",
  ///       "featured": true,
  ///       "image": "/images/burger.jpg",
  ///       "available": true
  ///     }
  ///   ]
  /// }
  /// ```
  /// Returns a [Result.success] containing `List<MenuItem>` on 200,
  /// or a [Result.failure] with user-friendly error message on network/server error.
  Future<Result<List<MenuItem>>> getMenuItems() async {
    try {
      final response = await _apiClient.dio.get<dynamic>('/api/menu');
      final data = response.data;

      final List<dynamic> rawList;
      if (data is Map<String, dynamic> && data['items'] is List) {
        rawList = data['items'] as List<dynamic>;
      } else if (data is List) {
        rawList = data;
      } else {
        return const Result.failure('Invalid menu data format from server.');
      }

      final items = rawList
          .whereType<Map<String, dynamic>>()
          .map(MenuItem.fromJson)
          .toList();

      return Result.success(items);
    } on DioException catch (e) {
      return ApiClient.failureFromDioException<List<MenuItem>>(e);
    } catch (e) {
      return Result.failure('Failed to load menu: $e');
    }
  }

  /// Updates the availability status of a menu item via `PATCH /api/menu/:id/availability`.
  ///
  /// Request body:
  /// ```json
  /// { "available": true | false }
  /// ```
  ///
  /// Returns a [Result.success] with the updated [MenuItem] on 200,
  /// or a [Result.failure] on error (e.g. 400 validation, 404 not found, 401 unauthorized, or network error).
  Future<Result<MenuItem>> setAvailability(
    String itemId,
    bool available,
  ) async {
    try {
      final response = await _apiClient.dio.patch<dynamic>(
        '/api/menu/$itemId/availability',
        data: <String, dynamic>{'available': available},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final updatedItem = MenuItem.fromJson(data);
        return Result.success(updatedItem);
      }
      return const Result.failure('Invalid response format from server.');
    } on DioException catch (e) {
      return ApiClient.failureFromDioException<MenuItem>(e);
    } catch (e) {
      return Result.failure('Failed to update availability: $e');
    }
  }

  /// Alias for [setAvailability] matching ARCHITECTURE.md §5.2.
  Future<Result<MenuItem>> patchAvailability(
    String itemId,
    bool available,
  ) =>
      setAvailability(itemId, available);

  /// Creates a new menu item via `POST /api/menu`.
  ///
  /// Returns [Result.success] with the created [MenuItem] on 201,
  /// or [Result.failure] on error (e.g. 400 validation error, 401 unauthorized, or network error).
  Future<Result<MenuItem>> createMenuItem(MenuItem item) async {
    try {
      final payload = <String, dynamic>{
        'name': item.name.trim(),
        'subtitle': item.subtitle.trim(),
        'price': item.price,
        'rating': 5.0,
        'categorySlug': item.categorySlug.trim(),
        'type': item.type,
        'featured': item.featured,
        'available': item.available,
        'image': (item.image != null && item.image!.trim().isNotEmpty)
            ? item.image!.trim()
            : '/images/placeholder.jpg',
      };

      final response = await _apiClient.dio.post<dynamic>(
        '/api/menu',
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final created = MenuItem.fromJson(data);
        return Result.success(created);
      }
      return const Result.failure('Invalid response format from server.');
    } on DioException catch (e) {
      return ApiClient.failureFromDioException<MenuItem>(e);
    } catch (e) {
      return Result.failure('Failed to create menu item: $e');
    }
  }

  /// Updates an existing menu item via `PUT /api/menu/:id`.
  ///
  /// Returns [Result.success] with the updated [MenuItem] on 200,
  /// or [Result.failure] on error (e.g. 400 validation, 404 not found, 401 unauthorized, or network error).
  Future<Result<MenuItem>> updateMenuItem(
    String id,
    MenuItem item,
  ) async {
    try {
      final payload = <String, dynamic>{
        'name': item.name.trim(),
        'subtitle': item.subtitle.trim(),
        'price': item.price,
        'categorySlug': item.categorySlug.trim(),
        'type': item.type,
        'featured': item.featured,
        'available': item.available,
      };
      if (item.image != null && item.image!.trim().isNotEmpty) {
        payload['image'] = item.image!.trim();
      }

      final response = await _apiClient.dio.put<dynamic>(
        '/api/menu/$id',
        data: payload,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final updated = MenuItem.fromJson(data);
        return Result.success(updated);
      }
      return const Result.failure('Invalid response format from server.');
    } on DioException catch (e) {
      return ApiClient.failureFromDioException<MenuItem>(e);
    } catch (e) {
      return Result.failure('Failed to update menu item: $e');
    }
  }

  /// Deletes a menu item via `DELETE /api/menu/:id`.
  ///
  /// Returns [Result.success] on 200,
  /// or [Result.failure] on error (e.g. 404 not found, 401 unauthorized, or network error).
  Future<Result<void>> deleteMenuItem(String id) async {
    try {
      final response = await _apiClient.dio.delete<dynamic>(
        '/api/menu/$id',
      );

      final statusCode = response.statusCode ?? 200;
      if (statusCode >= 200 && statusCode < 300) {
        return const Result.success(null);
      }
      return const Result.failure('Failed to delete menu item.');
    } on DioException catch (e) {
      return ApiClient.failureFromDioException<void>(e);
    } catch (e) {
      return Result.failure('Failed to delete menu item: $e');
    }
  }

  /// Fetches the list of active categories via `GET /api/categories`.
  ///
  /// Response payload shape:
  /// ```json
  /// [
  ///   {
  ///     "id": "6aaa25625a5c1215a384ba15",
  ///     "_id": "6aaa25625a5c1215a384ba15",
  ///     "name": "Sandwitch",
  ///     "slug": "sandwitch",
  ///     "icon": "🥪",
  ///     "sortOrder": 1
  ///   }
  /// ]
  /// ```
  /// Returns a [Result.success] containing `List<Category>` on 200,
  /// or a [Result.failure] with a user-friendly error message on error.
  Future<Result<List<Category>>> getCategories() async {
    try {
      final response = await _apiClient.dio.get<dynamic>('/api/categories');
      final data = response.data;

      final List<dynamic> rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic> && data['categories'] is List) {
        rawList = data['categories'] as List<dynamic>;
      } else {
        return const Result.failure(
          'Invalid categories data format from server.',
        );
      }

      final categories = rawList
          .whereType<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList();

      return Result.success(categories);
    } on DioException catch (e) {
      return ApiClient.failureFromDioException<List<Category>>(e);
    } catch (e) {
      return Result.failure('Failed to load categories: $e');
    }
  }
}

