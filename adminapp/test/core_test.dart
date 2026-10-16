import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:adminapp/core/api_client.dart';
import 'package:adminapp/core/constants.dart';
import 'package:adminapp/core/result.dart';
import 'package:adminapp/core/secure_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fake implementation of FlutterSecureStorage for deterministic unit testing.
class FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  AndroidOptions get aOptions => const AndroidOptions();

  @override
  IOSOptions get iOptions => const IOSOptions();

  @override
  LinuxOptions get lOptions => const LinuxOptions();

  @override
  MacOsOptions get mOptions => const MacOsOptions();

  @override
  WindowsOptions get wOptions => const WindowsOptions();

  @override
  WebOptions get webOptions => const WebOptions();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock HttpClientAdapter to test Dio requests and responses end-to-end.
class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConstants Core Tests (Task 1B-1)', () {
    test('Configures correct timeouts and dev URL', () {
      expect(AppConstants.devApiBaseUrl, isA<String>());
      expect(AppConstants.connectTimeout, const Duration(seconds: 15));
      expect(AppConstants.receiveTimeout, const Duration(seconds: 15));
      expect(AppConstants.sendTimeout, const Duration(seconds: 15));
      expect(AppConstants.secureStorageJwtKey, 'admin_jwt_token');
      expect(AppConstants.prodApiBaseUrl, 'https://sliceandserve.vercel.app');
      expect(AppConstants.apiBaseUrl, AppConstants.devApiBaseUrl);
    });
  });

  group('Result<T> Pattern Tests (Task 1B-1 & CODING_STANDARDS §1)', () {
    test('Success result exposes data and flags', () {
      const result = Result.success('test_data');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 'test_data');
      expect(result.errorOrNull, isNull);
    });

    test('Failure result exposes error message, status code, and error code', () {
      const result = Result<String>.failure(
        'Invalid credentials',
        statusCode: 401,
        errorCode: 'UNAUTHORIZED',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.errorOrNull, 'Invalid credentials');

      if (result is Failure<String>) {
        expect(result.statusCode, 401);
        expect(result.errorCode, 'UNAUTHORIZED');
      }
    });

    test('Result.map transforms successful data and preserves failure', () {
      const success = Result.success(42);
      final mappedSuccess = success.map((d) => 'Number: $d');
      expect(mappedSuccess, const Result.success('Number: 42'));

      const failure = Result<int>.failure(
        'Failed',
        statusCode: 400,
        errorCode: 'BAD_REQUEST',
      );
      final mappedFailure = failure.map((d) => 'Number: $d');
      expect(mappedFailure.isFailure, isTrue);
      expect(mappedFailure.errorOrNull, 'Failed');
    });

    test('Result.when pattern matching executes appropriate branch', () {
      const success = Result.success('hello');
      final sMsg = success.when(
        success: (d) => 'Got $d',
        failure: (m, sc, ec) => 'Error $m',
      );
      expect(sMsg, 'Got hello');

      const failure = Result<String>.failure('not found', statusCode: 404);
      final fMsg = failure.when(
        success: (d) => 'Got $d',
        failure: (m, sc, ec) => 'Error $m ($sc)',
      );
      expect(fMsg, 'Error not found (404)');
    });

    test('Result equality and hashCode compare value equality', () {
      expect(const Result.success('abc'), equals(const Result.success('abc')));
      expect(
        const Result<dynamic>.failure('err', statusCode: 500),
        equals(const Result<dynamic>.failure('err', statusCode: 500)),
      );
      expect(
        const Result.success('abc'),
        isNot(equals(const Result.success('def'))),
      );
    });
  });

  group('SecureStore Tests (Task 1B-1 & ARCHITECTURE §9)', () {
    late FakeSecureStorage fakeStorage;
    late SecureStore secureStore;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      secureStore = SecureStore(storage: fakeStorage);
    });

    test('Saves, reads, checks, and clears JWT token', () async {
      expect(await secureStore.hasToken(), isFalse);
      expect(await secureStore.getToken(), isNull);

      await secureStore.saveToken('jwt_sample_12345');
      expect(await secureStore.hasToken(), isTrue);
      expect(await secureStore.getToken(), 'jwt_sample_12345');

      await secureStore.clearToken();
      expect(await secureStore.hasToken(), isFalse);
      expect(await secureStore.getToken(), isNull);
    });
  });

  group('ApiClient Tests (Task 1B-1)', () {
    late FakeSecureStorage fakeStorage;
    late SecureStore secureStore;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      secureStore = SecureStore(storage: fakeStorage);
    });

    test('Attaches Bearer token to requests except /api/admin/login', () async {
      await secureStore.saveToken('my_secret_jwt');

      RequestOptions? interceptedOptions;
      final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        interceptedOptions = options;
        return ResponseBody.fromString(
          jsonEncode({'success': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final apiClient = ApiClient(
        customDio: dio,
        customSecureStore: secureStore,
      );

      // Normal protected endpoint request
      await apiClient.dio.get<dynamic>('/api/orders');
      expect(interceptedOptions?.headers['Authorization'], 'Bearer my_secret_jwt');

      // Login endpoint request should NOT have Authorization header attached
      await apiClient.dio.post<dynamic>('/api/admin/login');
      expect(interceptedOptions?.headers['Authorization'], isNull);

      apiClient.dispose();
    });

    test('401 response clears token and emits onUnauthorized event', () async {
      await secureStore.saveToken('expired_jwt');
      expect(await secureStore.hasToken(), isTrue);

      final dio = Dio(BaseOptions(baseUrl: 'http://example.com'));
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'error': {'message': 'Unauthorized'}}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final apiClient = ApiClient(
        customDio: dio,
        customSecureStore: secureStore,
      );

      var callbackInvoked = false;
      apiClient.onUnauthorizedCallback = () {
        callbackInvoked = true;
      };

      var streamEventReceived = false;
      final sub = apiClient.onUnauthorized.listen((_) {
        streamEventReceived = true;
      });

      try {
        await apiClient.dio.get<dynamic>('/api/orders');
      } catch (_) {
        // Expected DioException on 401
      }

      // Verify token cleared
      expect(await secureStore.hasToken(), isFalse);
      expect(callbackInvoked, isTrue);
      // Wait microtask for stream
      await Future<void>.delayed(Duration.zero);
      expect(streamEventReceived, isTrue);

      await sub.cancel();
      apiClient.dispose();
    });

    test('Parses backend error envelope into Failure<T>', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/orders/ORD-101/complete'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/orders/ORD-101/complete'),
          statusCode: 400,
          data: {
            'error': {
              'code': 'INVALID_TRANSITION',
              'message': 'Cannot complete a pending order.',
            }
          },
        ),
      );

      final failure = ApiClient.failureFromDioException<void>(dioException);
      expect(failure.errorMessage, 'Cannot complete a pending order.');
      expect(failure.statusCode, 400);
      expect(failure.errorCode, 'INVALID_TRANSITION');
    });

    test('Parses network timeout into user-friendly message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/menu'),
        type: DioExceptionType.connectionTimeout,
      );

      final failure = ApiClient.failureFromDioException<void>(dioException);
      expect(failure.errorMessage, contains('Connection timed out'));
      expect(failure.statusCode, isNull);
    });
  });

  group('Real Backend Connectivity Test (Production & Dev Checkpoint)', () {
    test('GET /api/health returns 200 and status ok via ApiClient', () async {
      HttpOverrides.global = null;
      final fakeStorage = FakeSecureStorage();
      final secureStore = SecureStore(storage: fakeStorage);
      final realClient = ApiClient(
        customSecureStore: secureStore,
        baseUrl: AppConstants.prodApiBaseUrl,
      );
      try {
        final response = await realClient.dio.get<Map<String, dynamic>>('/api/health');
        expect(response.statusCode, 200);
        expect(response.data, isNotNull);
        expect(response.data!['status'], 'ok');
      } catch (e) {
        fail('Failed to connect to server at ${realClient.dio.options.baseUrl}: $e');
      } finally {
        realClient.dispose();
      }
    });
  });
}
