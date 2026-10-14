import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/core/api_client.dart';
import 'package:adminapp/core/result.dart';
import 'package:adminapp/core/secure_store.dart';
import 'package:adminapp/models/loyalty_card.dart';
import 'package:adminapp/services/loyalty_service.dart';

void main() {
  late SecureStore secureStore;

  setUp(() {
    secureStore = SecureStore();
  });

  group('LoyaltyService Tests (Task 3B-2)', () {
    test('scanToken parses nested ScanResponse envelope successfully', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/loyalty/scan/valid_stamp_token');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'customer': {
                    'name': 'Smruti Rout',
                  },
                  'card': {
                    'stamps': 3,
                    'totalRequired': 10,
                    'rewardReady': false,
                  },
                  'action': 'stamp',
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = LoyaltyService(apiClient: client);

      final result = await service.scanToken('valid_stamp_token');

      expect(result.isSuccess, isTrue);
      final data = (result as Success).data;
      expect(data.customerName, 'Smruti Rout');
      expect(data.stamps, 3);
      expect(data.totalRequired, 10);
      expect(data.rewardReady, isFalse);
      expect(data.action, 'stamp');
      expect(data.isStampAction, isTrue);
      expect(data.isRedeemAction, isFalse);
    });

    test('scanToken parses redeem action with rewardReady true', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/loyalty/scan/valid_redeem_token');
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'customer': {
                    'name': 'Smrutiprakash Rout',
                  },
                  'card': {
                    'stamps': 10,
                    'totalRequired': 10,
                    'rewardReady': true,
                  },
                  'action': 'redeem',
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = LoyaltyService(apiClient: client);

      final result = await service.scanToken('valid_redeem_token');

      expect(result.isSuccess, isTrue);
      final data = (result as Success).data;
      expect(data.customerName, 'Smrutiprakash Rout');
      expect(data.stamps, 10);
      expect(data.totalRequired, 10);
      expect(data.rewardReady, isTrue);
      expect(data.action, 'redeem');
      expect(data.isRedeemAction, isTrue);
    });

    test('scanToken handles 404 TOKEN_NOT_FOUND as a distinct failure', () async {
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
                      'code': 'TOKEN_NOT_FOUND',
                      'message': "This QR code doesn't match any customer.",
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
      final service = LoyaltyService(apiClient: client);

      final result = await service.scanToken('unknown_token_999');

      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.statusCode, 404);
      expect(failure.errorCode, 'TOKEN_NOT_FOUND');
      expect(failure.errorMessage, "This QR code doesn't match any customer.");
    });

    test('scanToken handles 500 server error', () async {
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
                      'message': 'Internal Server Error.',
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
      final service = LoyaltyService(apiClient: client);

      final result = await service.scanToken('token_500');

      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.statusCode, 500);
      expect(failure.errorMessage, 'Internal Server Error.');
    });

    test('scanToken handles connection timeout error', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionTimeout,
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = LoyaltyService(apiClient: client);

      final result = await service.scanToken('timeout_token');

      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.errorMessage, contains('Connection timed out'));
    });

    test('scanToken returns immediate failure on empty token string', () async {
      final client = ApiClient(customSecureStore: secureStore);
      final service = LoyaltyService(apiClient: client);

      final result = await service.scanToken('   ');

      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.statusCode, 400);
      expect(failure.errorCode, 'INVALID_TOKEN');
    });

    test('scanToken properly encodes special characters in path', () async {
      String? requestedPath;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPath = options.path;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'customer': {'name': 'Special Char User'},
                  'card': {'stamps': 1, 'totalRequired': 10, 'rewardReady': false},
                  'action': 'stamp',
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = LoyaltyService(apiClient: client);

      await service.scanToken('token with spaces&special/chars');

      expect(
        requestedPath,
        '/api/loyalty/scan/token%20with%20spaces%26special%2Fchars',
      );
    });
  });

  group('LoyaltyService.addStamp Tests (Task 3B-3)', () {
    test('POST /api/loyalty/:customerId/stamp succeeds and increments card', () async {
      String? requestedMethod;
      String? requestedPath;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedMethod = options.method;
            requestedPath = options.path;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'stamps': 3,
                  'totalRequired': 10,
                  'rewardReady': false,
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = LoyaltyService(apiClient: client);

      const current = LoyaltyScanResult(
        customerId: 'cust-123',
        customerName: 'Smruti Rout',
        stamps: 2,
        totalRequired: 10,
        rewardReady: false,
        action: 'stamp',
      );

      final result = await service.addStamp('cust-123', currentResult: current);

      expect(requestedMethod, 'POST');
      expect(requestedPath, '/api/loyalty/cust-123/stamp');
      expect(result.isSuccess, isTrue);
      final data = (result as Success<LoyaltyScanResult>).data;
      expect(data.customerId, 'cust-123');
      expect(data.customerName, 'Smruti Rout');
      expect(data.stamps, 3);
      expect(data.totalRequired, 10);
      expect(data.rewardReady, isFalse);
    });

    test('addStamp flips rewardReady to true when stamps reach totalRequired', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'stamps': 10,
                  'totalRequired': 10,
                  'rewardReady': true,
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = LoyaltyService(apiClient: client);

      const current = LoyaltyScanResult(
        customerId: 'cust-123',
        customerName: 'Smruti Rout',
        stamps: 9,
        totalRequired: 10,
        rewardReady: false,
        action: 'stamp',
      );

      final result = await service.addStamp('cust-123', currentResult: current);

      expect(result.isSuccess, isTrue);
      final data = (result as Success<LoyaltyScanResult>).data;
      expect(data.stamps, 10);
      expect(data.rewardReady, isTrue);
    });

    test('addStamp handles 409 REWARD_ALREADY_READY conflict rejection', () async {
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
                      'code': 'REWARD_ALREADY_READY',
                      'message':
                          "This customer's reward is ready to redeem — stamp it after they redeem, not before.",
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
      final service = LoyaltyService(apiClient: client);

      final result = await service.addStamp('cust-full-card');

      expect(result.isFailure, isTrue);
      final failure = result as Failure<LoyaltyScanResult>;
      expect(failure.statusCode, 409);
      expect(failure.errorCode, 'REWARD_ALREADY_READY');
      expect(
        failure.errorMessage,
        "This customer's reward is ready to redeem — stamp it after they redeem, not before.",
      );
    });

    test('addStamp handles 404 NOT_FOUND when customer does not exist', () async {
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
                      'message': 'Customer not found.',
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
      final service = LoyaltyService(apiClient: client);

      final result = await service.addStamp('nonexistent-id');

      expect(result.isFailure, isTrue);
      final failure = result as Failure<LoyaltyScanResult>;
      expect(failure.statusCode, 404);
      expect(failure.errorMessage, 'Customer not found.');
    });

    test('addStamp rejects empty customerId before network call', () async {
      final client = ApiClient(customSecureStore: secureStore);
      final service = LoyaltyService(apiClient: client);

      final result = await service.addStamp('   ');

      expect(result.isFailure, isTrue);
      final failure = result as Failure<LoyaltyScanResult>;
      expect(failure.statusCode, 400);
      expect(failure.errorCode, 'INVALID_CUSTOMER_ID');
    });
  });

  group('LoyaltyService.redeemReward Tests (Task 3B-3)', () {
    test('POST /api/loyalty/:customerId/redeem succeeds and resets card', () async {
      String? requestedMethod;
      String? requestedPath;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedMethod = options.method;
            requestedPath = options.path;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'stamps': 0,
                  'totalRequired': 10,
                  'rewardReady': false,
                },
              ),
            );
          },
        ),
      );

      final client = ApiClient(customDio: dio, customSecureStore: secureStore);
      final service = LoyaltyService(apiClient: client);

      const current = LoyaltyScanResult(
        customerId: 'cust-456',
        customerName: 'Smrutiprakash Rout',
        stamps: 10,
        totalRequired: 10,
        rewardReady: true,
        action: 'redeem',
      );

      final result =
          await service.redeemReward('cust-456', currentResult: current);

      expect(requestedMethod, 'POST');
      expect(requestedPath, '/api/loyalty/cust-456/redeem');
      expect(result.isSuccess, isTrue);
      final data = (result as Success<LoyaltyScanResult>).data;
      expect(data.customerId, 'cust-456');
      expect(data.customerName, 'Smrutiprakash Rout');
      expect(data.stamps, 0);
      expect(data.rewardReady, isFalse);
    });

    test('redeemReward handles 409 REWARD_NOT_READY when card is not full', () async {
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
                      'code': 'REWARD_NOT_READY',
                      'message': "This customer's card isn't full yet.",
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
      final service = LoyaltyService(apiClient: client);

      final result = await service.redeemReward('cust-not-ready');

      expect(result.isFailure, isTrue);
      final failure = result as Failure<LoyaltyScanResult>;
      expect(failure.statusCode, 409);
      expect(failure.errorCode, 'REWARD_NOT_READY');
      expect(failure.errorMessage, "This customer's card isn't full yet.");
    });

    test('redeemReward rejects empty customerId', () async {
      final client = ApiClient(customSecureStore: secureStore);
      final service = LoyaltyService(apiClient: client);

      final result = await service.redeemReward('');

      expect(result.isFailure, isTrue);
      final failure = result as Failure<LoyaltyScanResult>;
      expect(failure.statusCode, 400);
      expect(failure.errorCode, 'INVALID_CUSTOMER_ID');
    });
  });
}
