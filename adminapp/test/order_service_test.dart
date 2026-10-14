import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/core/api_client.dart';
import 'package:adminapp/core/result.dart';
import 'package:adminapp/core/secure_store.dart';
import 'package:adminapp/services/order_service.dart';

void main() {
  late SecureStore secureStore;

  setUp(() {
    secureStore = SecureStore();
  });

  group('OrderService Tests (Task 4B-1)', () {
    test('getOrders fetches orders with status query parameter on 200', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/orders');
            expect(options.queryParameters['status'], 'pending');

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'orders': [
                    {
                      'id': 'ORD-TEST-1',
                      'customerName': 'Smrutiprakash Rout',
                      'fulfillment': 'dine-in',
                      'tableNumber': '4',
                      'items': [
                        {
                          'name': 'Chicken Burger',
                          'price': 79.0,
                          'quantity': 2,
                        }
                      ],
                      'total': 158.0,
                      'status': 'pending',
                      'placedAt': '2026-10-04T12:00:00.000Z',
                    }
                  ],
                  'total': 1,
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final orderService = OrderService(apiClient: client);

      final result = await orderService.getOrders(status: 'pending');

      expect(result.isSuccess, isTrue);
      final orders = (result as Success).data;
      expect(orders.length, 1);

      final order = orders.first;
      expect(order.id, 'ORD-TEST-1');
      expect(order.customerName, 'Smrutiprakash Rout');
      expect(order.fulfillment, 'dine-in');
      expect(order.tableNumber, '4');
      expect(order.items.length, 1);
      expect(order.items.first.name, 'Chicken Burger');
      expect(order.items.first.quantity, 2);
      expect(order.items.first.price, 79.0);
      expect(order.total, 158.0);
      expect(order.status, 'pending');
    });

    test('getOrders handles gracefully absent tableNumber for dine-in', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'orders': [
                    {
                      'id': 'ORD-TEST-2',
                      'customerName': 'Smruti Rout',
                      'fulfillment': 'dine-in',
                      'items': <Map<String, dynamic>>[],
                      'total': 79.0,
                      'status': 'pending',
                      'placedAt': '2026-10-04T12:05:00.000Z',
                    }
                  ],
                  'total': 1,
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final orderService = OrderService(apiClient: client);

      final result = await orderService.getOrders(status: 'pending');

      expect(result.isSuccess, isTrue);
      final order = (result as Success).data.first;
      expect(order.isDineIn, isTrue);
      expect(order.tableNumber, isNull);
    });

    test('getOrders parses raw list response if server omits envelope', () async {
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
                    'id': 'ORD-RAW',
                    'customerName': 'Direct List',
                    'fulfillment': 'pickup',
                    'items': <Map<String, dynamic>>[],
                    'total': 100.0,
                    'status': 'accepted',
                    'placedAt': '2026-10-04T12:00:00.000Z',
                  }
                ],
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final orderService = OrderService(apiClient: client);

      final result = await orderService.getOrders(status: 'accepted');

      expect(result.isSuccess, isTrue);
      expect((result as Success).data.first.customerName, 'Direct List');
    });

    test('getOrders returns Result.failure on DioException 500 error', () async {
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
                      'code': 'INTERNAL_SERVER_ERROR',
                      'message': 'Database connection lost.',
                    },
                  },
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final orderService = OrderService(apiClient: client);

      final result = await orderService.getOrders(status: 'pending');

      expect(result.isFailure, isTrue);
      expect((result as Failure).errorMessage, 'Database connection lost.');
    });

    test('getOrders returns Result.failure on malformed response data', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: 'unexpected string response',
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final orderService = OrderService(apiClient: client);

      final result = await orderService.getOrders();

      expect(result.isFailure, isTrue);
      expect((result as Failure).errorMessage, contains('Invalid orders data format'));
    });
  });

  group('OrderService Actions Tests (Task 4B-2)', () {
    test('acceptOrder PATCHes /api/orders/:id/accept and returns updated order on 200', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'PATCH');
            expect(options.path, '/api/orders/ORD-101/accept');

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'ORD-101',
                  'customerName': 'Aarav Mehta',
                  'fulfillment': 'pickup',
                  'items': <Map<String, dynamic>>[],
                  'total': 249.0,
                  'status': 'accepted',
                  'placedAt': '2026-10-04T12:00:00.000Z',
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final orderService = OrderService(apiClient: client);

      final result = await orderService.acceptOrder('ORD-101');

      expect(result.isSuccess, isTrue);
      final order = (result as Success).data;
      expect(order.id, 'ORD-101');
      expect(order.status, 'accepted');
    });

    test('rejectOrder PATCHes /api/orders/:id/reject and returns updated order on 200', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'PATCH');
            expect(options.path, '/api/orders/ORD-102/reject');

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'ORD-102',
                  'customerName': 'Priya Sundaram',
                  'fulfillment': 'dine-in',
                  'items': <Map<String, dynamic>>[],
                  'total': 189.0,
                  'status': 'rejected',
                  'placedAt': '2026-10-04T12:05:00.000Z',
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final orderService = OrderService(apiClient: client);

      final result = await orderService.rejectOrder('ORD-102');

      expect(result.isSuccess, isTrue);
      final order = (result as Success).data;
      expect(order.id, 'ORD-102');
      expect(order.status, 'rejected');
    });

    test('completeOrder PATCHes /api/orders/:id/complete and returns updated order on 200', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.method, 'PATCH');
            expect(options.path, '/api/orders/ORD-104/complete');

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'ORD-104',
                  'customerName': 'Riya Sharma',
                  'fulfillment': 'pickup',
                  'items': <Map<String, dynamic>>[],
                  'total': 189.0,
                  'status': 'completed',
                  'placedAt': '2026-10-04T11:45:00.000Z',
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final orderService = OrderService(apiClient: client);

      final result = await orderService.completeOrder('ORD-104');

      expect(result.isSuccess, isTrue);
      final order = (result as Success).data;
      expect(order.id, 'ORD-104');
      expect(order.status, 'completed');
    });

    test('Handles 409 Conflict with clear message and status code', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: {
                    'error': {
                      'code': 'INVALID_TRANSITION',
                      'message': 'Cannot transition an order from accepted to accepted.',
                    },
                  },
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final orderService = OrderService(apiClient: client);

      final result = await orderService.acceptOrder('ORD-STALE');

      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.statusCode, 409);
      expect(failure.errorCode, 'INVALID_TRANSITION');
      expect(failure.errorMessage, 'Cannot transition an order from accepted to accepted.');
    });

    test('Returns Result.failure on generic network error', () async {
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
                      'message': 'Internal Server Error',
                    },
                  },
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final orderService = OrderService(apiClient: client);

      final result = await orderService.completeOrder('ORD-500');

      expect(result.isFailure, isTrue);
      expect((result as Failure).errorMessage, 'Internal Server Error');
    });
  });
}
