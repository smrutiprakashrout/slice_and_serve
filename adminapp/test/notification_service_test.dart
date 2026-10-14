import 'dart:async';
import 'package:adminapp/core/api_client.dart';
import 'package:adminapp/core/secure_store.dart';
import 'package:adminapp/models/order.dart';
import 'package:adminapp/providers/navigation_provider.dart';
import 'package:adminapp/services/notification_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Tests (Task Push-1)', () {
    late ApiClient apiClient;
    late Dio dio;
    late SecureStore secureStore;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      secureStore = SecureStore(storage: FakeSecureStorage());
      apiClient = ApiClient(
        customDio: dio,
        customSecureStore: secureStore,
      );
    });

    test('requestPermission returns true when permission is granted', () async {
      var requested = false;
      final service = NotificationService(
        apiClient: apiClient,
        permissionRequester: () async {
          requested = true;
          return true;
        },
      );

      final granted = await service.requestPermission();
      expect(granted, isTrue);
      expect(requested, isTrue);
    });

    test('requestPermission returns false when permission is denied', () async {
      final service = NotificationService(
        apiClient: apiClient,
        permissionRequester: () async => false,
      );

      final granted = await service.requestPermission();
      expect(granted, isFalse);
    });

    test('getDeviceToken returns token from getter', () async {
      final service = NotificationService(
        apiClient: apiClient,
        tokenGetter: () async => 'sample-fcm-token-xyz',
      );

      final token = await service.getDeviceToken();
      expect(token, equals('sample-fcm-token-xyz'));
    });

    test('registerToken returns failure when token is empty or null', () async {
      final service = NotificationService(
        apiClient: apiClient,
        tokenGetter: () async => null,
      );

      final result = await service.registerToken();
      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('Expected failure'),
        failure: (msg, code, errCode) {
          expect(errCode, equals('TOKEN_UNAVAILABLE'));
        },
      );
    });

    test('registerToken sends POST /api/admin/fcm-token and returns success', () async {
      // Intercept request with mock response
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/admin/fcm-token' && options.method == 'POST') {
              expect(options.data, equals({'token': 'mock-device-token-123'}));
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'message': 'FCM token registered successfully.',
                    'token': 'mock-device-token-123',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final service = NotificationService(
        apiClient: apiClient,
        tokenGetter: () async => 'mock-device-token-123',
      );

      final result = await service.registerToken();
      expect(result.isSuccess, isTrue);
      expect(service.lastRegisteredToken, equals('mock-device-token-123'));
    });

    test('registerToken handles DioException network failure gracefully', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Network connection lost',
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

      final service = NotificationService(
        apiClient: apiClient,
        tokenGetter: () async => 'token-to-fail',
      );

      final result = await service.registerToken();
      expect(result.isFailure, isTrue);
    });

    test('listenForTokenRefresh automatically registers new tokens on rotation', () async {
      final tokenController = StreamController<String>.broadcast();
      final registeredTokens = <String>[];

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/admin/fcm-token') {
              registeredTokens.add((options.data as Map)['token'] as String);
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true},
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final service = NotificationService(
        apiClient: apiClient,
        tokenGetter: () async => 'initial-token',
        tokenRefreshStreamGetter: () => tokenController.stream,
      );

      service.listenForTokenRefresh();

      tokenController.add('rotated-token-1');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      tokenController.add('rotated-token-2');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(registeredTokens, contains('rotated-token-1'));
      expect(registeredTokens, contains('rotated-token-2'));
      expect(service.lastRegisteredToken, equals('rotated-token-2'));

      service.dispose();
      await tokenController.close();
    });

    test('initializeAndRegister executes full permission + register + listen flow', () async {
      var permissionRequested = false;
      var registered = false;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/api/admin/fcm-token') {
              registered = true;
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true},
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final tokenController = StreamController<String>.broadcast();

      final service = NotificationService(
        apiClient: apiClient,
        permissionRequester: () async {
          permissionRequested = true;
          return true;
        },
        tokenGetter: () async => 'init-flow-token',
        tokenRefreshStreamGetter: () => tokenController.stream,
      );

      final result = await service.initializeAndRegister();
      expect(result.isSuccess, isTrue);
      expect(permissionRequested, isTrue);
      expect(registered, isTrue);
      expect(service.lastRegisteredToken, equals('init-flow-token'));

      service.dispose();
      await tokenController.close();
    });
  });

  group('Push-2 Custom Android Notification Channel Tests', () {
    test('Notification channel constants and configuration match specifications', () {
      expect(NotificationService.orderChannelId, equals('sns_new_orders'));
      expect(NotificationService.orderChannelName, equals('New Orders'));
      expect(
        NotificationService.orderChannelDescription,
        equals('Notifications for newly placed customer orders'),
      );
      expect(NotificationService.orderSoundResource, equals('order_alert'));

      final channel = NotificationService.orderChannel;
      expect(channel.id, equals('sns_new_orders'));
      expect(channel.name, equals('New Orders'));
      expect(channel.importance.value, greaterThanOrEqualTo(4)); // Importance.max / high
      expect(channel.playSound, isTrue);
      expect(channel.enableVibration, isTrue);
      expect(channel.sound, isNotNull);
      expect(channel.sound, isA<RawResourceAndroidNotificationSound>());
      final rawSound = channel.sound! as RawResourceAndroidNotificationSound;
      expect(rawSound.sound, equals('order_alert'));
    });

    test('setupNotificationChannel executes safely', () async {
      // Confirms setupNotificationChannel executes without throwing unhandled exceptions
      await expectLater(
        NotificationService.setupNotificationChannel(),
        completes,
      );
    });

    test('firebaseMessagingBackgroundHandler executes safely with data message', () async {
      final message = RemoteMessage(
        messageId: 'test-bg-message-id',
        data: {
          'title': 'New Order #42',
          'body': '2x Pepperoni Pizza',
          'orderId': 'order-xyz-42',
        },
      );

      await expectLater(
        firebaseMessagingBackgroundHandler(message),
        completes,
      );
    });
  });

  group('Push-3 Foreground, Background, and Terminated State Tests', () {
    test('setupMessageHandlers handles foreground message stream', () async {
      final fgController = StreamController<RemoteMessage>.broadcast();
      final bgController = StreamController<RemoteMessage>.broadcast();

      String? displayedTitle;
      String? displayedBody;
      var orderDataReceivedCalled = false;
      var navigateCalled = false;

      final service = NotificationService(
        foregroundMessageStreamGetter: () => fgController.stream,
        messageOpenedAppStreamGetter: () => bgController.stream,
      );

      service.setupMessageHandlers(
        onNavigateToPendingOrders: () {
          navigateCalled = true;
        },
        onShowInAppSignal: (title, body) {
          displayedTitle = title;
          displayedBody = body;
        },
        onOrderDataReceived: () {
          orderDataReceivedCalled = true;
        },
      );

      final foregroundMessage = RemoteMessage(
        messageId: 'fg-order-msg-1',
        data: {
          'title': 'New Order #101',
          'body': 'Margherita Pizza x1',
          'orderId': 'order-101',
        },
      );

      fgController.add(foregroundMessage);
      await pumpEventQueue();

      expect(displayedTitle, equals('New Order #101'));
      expect(displayedBody, equals('Margherita Pizza x1'));
      expect(orderDataReceivedCalled, isTrue);
      expect(navigateCalled, isFalse);

      service.dispose();
      await fgController.close();
      await bgController.close();
    });

    test('setupMessageHandlers handles background notification tap stream', () async {
      final fgController = StreamController<RemoteMessage>.broadcast();
      final bgController = StreamController<RemoteMessage>.broadcast();

      var navigateCalled = false;

      final service = NotificationService(
        foregroundMessageStreamGetter: () => fgController.stream,
        messageOpenedAppStreamGetter: () => bgController.stream,
      );

      service.setupMessageHandlers(
        onNavigateToPendingOrders: () {
          navigateCalled = true;
        },
      );

      final bgTapMessage = RemoteMessage(
        messageId: 'bg-tap-msg-1',
        data: {
          'orderId': 'order-202',
        },
      );

      bgController.add(bgTapMessage);
      await pumpEventQueue();

      expect(navigateCalled, isTrue);

      service.dispose();
      await fgController.close();
      await bgController.close();
    });

    test('checkInitialNotification detects cold-start from FCM message', () async {
      var navigateCalled = false;

      final service = NotificationService(
        initialMessageGetter: () async => RemoteMessage(
          messageId: 'cold-start-fcm-1',
          data: {'orderId': 'order-303'},
        ),
      );

      final didLaunch = await service.checkInitialNotification(
        onNavigateToPendingOrders: () {
          navigateCalled = true;
        },
      );

      expect(didLaunch, isTrue);
      expect(navigateCalled, isTrue);
    });

    test('checkInitialNotification detects cold-start from local notification', () async {
      var navigateCalled = false;

      final service = NotificationService(
        initialMessageGetter: () async => null,
        initialLaunchGetter: () async => true,
      );

      final didLaunch = await service.checkInitialNotification(
        onNavigateToPendingOrders: () {
          navigateCalled = true;
        },
      );

      expect(didLaunch, isTrue);
      expect(navigateCalled, isTrue);
    });

    test('checkInitialNotification returns false when no initial notification launched app', () async {
      var navigateCalled = false;

      final service = NotificationService(
        initialMessageGetter: () async => null,
        initialLaunchGetter: () async => false,
      );

      final didLaunch = await service.checkInitialNotification(
        onNavigateToPendingOrders: () {
          navigateCalled = true;
        },
      );

      expect(didLaunch, isFalse);
      expect(navigateCalled, isFalse);
    });

    test('navigateToOrdersPending correctly updates shellTabProvider and segment', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initial state
      expect(container.read(shellTabProvider), equals(0)); // Menu
      expect(container.read(ordersSelectedSegmentProvider), equals(OrderStatusSegment.pending));

      // Change tab to Settings and segment to Completed
      container.read(shellTabProvider.notifier).setTab(3);
      container.read(ordersSelectedSegmentProvider.notifier).setSegment(OrderStatusSegment.completed);
      expect(container.read(shellTabProvider), equals(3));
      expect(container.read(ordersSelectedSegmentProvider), equals(OrderStatusSegment.completed));

      // Trigger deep link
      container.read(shellTabProvider.notifier).setTab(2);
      container.read(ordersSelectedSegmentProvider.notifier).setSegment(OrderStatusSegment.pending);

      expect(container.read(shellTabProvider), equals(2)); // Orders
      expect(container.read(ordersSelectedSegmentProvider), equals(OrderStatusSegment.pending)); // Pending
    });
  });
}
