import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/result.dart';
import '../models/order.dart';

/// Service responsible for fetching orders from the backend API.
///
/// Implements `ARCHITECTURE.md` §4 (`GET /api/orders?status=`),
/// `CODING_STANDARDS.md` §1, §4, and `TASKS.md` Phase 4B (4B-1).
class OrderService {
  final ApiClient _apiClient;

  OrderService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches orders via `GET /api/orders?status=...`.
  ///
  /// Response payload shape from the Next.js admin API:
  /// ```json
  /// {
  ///   "orders": [
  ///     {
  ///       "id": "...",
  ///       "_id": "...",
  ///       "customerId": "...",
  ///       "customerName": "Smrutiprakash Rout",
  ///       "fulfillment": "dine-in",
  ///       "tableNumber": "4",
  ///       "items": [
  ///         {
  ///           "name": "Chicken Burger",
  ///           "price": 79.0,
  ///           "quantity": 1
  ///         }
  ///       ],
  ///       "total": 79.0,
  ///       "status": "pending",
  ///       "placedAt": "2026-10-04T..."
  ///     }
  ///   ],
  ///   "total": 1
  /// }
  /// ```
  /// When [status] is provided, adds `status: status` query parameter.
  /// Valid statuses per the backend API are: 'pending', 'accepted', 'completed', 'rejected'.
  ///
  /// Returns [Result.success] containing `List<Order>` on 200,
  /// or [Result.failure] on network/server error.
  Future<Result<List<Order>>> getOrders({
    String? status,
    int? limit,
    int? skip,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': ?limit,
        'skip': ?skip,
      };

      final response = await _apiClient.dio.get<dynamic>(
        '/api/orders',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data;
      final List<dynamic> rawList;
      if (data is Map<String, dynamic> && data['orders'] is List) {
        rawList = data['orders'] as List<dynamic>;
      } else if (data is List) {
        rawList = data;
      } else {
        return const Result.failure('Invalid orders data format from server.');
      }

      final orders = rawList
          .whereType<Map<String, dynamic>>()
          .map(Order.fromJson)
          .toList();

      return Result.success(orders);
    } on DioException catch (e) {
      return ApiClient.failureFromDioException<List<Order>>(e);
    } catch (e) {
      return Result.failure('Failed to load orders: $e');
    }
  }

  /// Transitions a pending order to accepted via `PATCH /api/orders/:id/accept`.
  ///
  /// Returns [Result.success] containing the updated [Order] on 200,
  /// or [Result.failure] on error. Specifically handles 409 (INVALID_TRANSITION)
  /// with a descriptive conflict message.
  Future<Result<Order>> acceptOrder(String id) => _patchOrderStatus(id, 'accept');

  /// Transitions a pending order to rejected via `PATCH /api/orders/:id/reject`.
  ///
  /// Returns [Result.success] containing the updated [Order] on 200,
  /// or [Result.failure] on error. Specifically handles 409 (INVALID_TRANSITION).
  Future<Result<Order>> rejectOrder(String id) => _patchOrderStatus(id, 'reject');

  /// Transitions an accepted order to completed via `PATCH /api/orders/:id/complete`.
  ///
  /// Returns [Result.success] containing the updated [Order] on 200,
  /// or [Result.failure] on error. Specifically handles 409 (INVALID_TRANSITION).
  Future<Result<Order>> completeOrder(String id) => _patchOrderStatus(id, 'complete');

  /// Helper for order PATCH actions (`accept`, `reject`, `complete`).
  Future<Result<Order>> _patchOrderStatus(String id, String action) async {
    try {
      final response = await _apiClient.dio.patch<dynamic>('/api/orders/$id/$action');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Result.success(Order.fromJson(data));
      }
      return const Result.failure('Invalid order data received from server.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final failure = ApiClient.failureFromDioException<Order>(e);
        final message = failure.errorMessage.isNotEmpty &&
                failure.errorMessage != 'Request failed with status code 409.'
            ? failure.errorMessage
            : 'Order status has already changed. Please refresh.';
        return Result.failure(
          message,
          statusCode: 409,
          errorCode: failure.errorCode ?? 'INVALID_TRANSITION',
        );
      }
      return ApiClient.failureFromDioException<Order>(e);
    } catch (e) {
      return Result.failure('Failed to $action order: $e');
    }
  }
}

