import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/api_client.dart';
import '../core/result.dart';

/// Type definitions for testable notification dependencies.
typedef TokenGetter = Future<String?> Function();
typedef PermissionRequester = Future<bool> Function();
typedef TokenRefreshStreamGetter = Stream<String> Function();
typedef ForegroundMessageStreamGetter = Stream<RemoteMessage> Function();
typedef MessageOpenedAppStreamGetter = Stream<RemoteMessage> Function();
typedef InitialMessageGetter = Future<RemoteMessage?> Function();
typedef InitialLaunchGetter = Future<bool> Function();

/// Service responsible for managing push notification permissions, obtaining the device's
/// FCM token, registering it with the backend via `POST /api/admin/fcm-token`, and handling
/// token rotation.
///
/// Implements `ARCHITECTURE.md` §4, §6 and `PRD.md` §3.6 (A-30).
class NotificationService {
  final ApiClient _apiClient;
  final TokenGetter? tokenGetter;
  final PermissionRequester? permissionRequester;
  final TokenRefreshStreamGetter? tokenRefreshStreamGetter;
  final ForegroundMessageStreamGetter? foregroundMessageStreamGetter;
  final MessageOpenedAppStreamGetter? messageOpenedAppStreamGetter;
  final InitialMessageGetter? initialMessageGetter;
  final InitialLaunchGetter? initialLaunchGetter;

  StreamSubscription<String>? _refreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  String? _lastRegisteredToken;

  NotificationService({
    ApiClient? apiClient,
    this.tokenGetter,
    this.permissionRequester,
    this.tokenRefreshStreamGetter,
    this.foregroundMessageStreamGetter,
    this.messageOpenedAppStreamGetter,
    this.initialMessageGetter,
    this.initialLaunchGetter,
  })  : _apiClient = apiClient ?? ApiClient();

  /// The most recent token successfully registered with the backend.
  String? get lastRegisteredToken => _lastRegisteredToken;

  /// Requests notification permission from the operating system (Android 13+ POST_NOTIFICATIONS).
  ///
  /// Safe to call on any platform/version. Returns `true` if permission was granted.
  Future<bool> requestPermission() async {
    final requester = permissionRequester;
    if (requester != null) {
      return await requester();
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isGranted = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('[NotificationService] Permission status: ${settings.authorizationStatus}');
      return isGranted;
    } catch (e) {
      debugPrint('[NotificationService] Error requesting notification permission: $e');
      return false;
    }
  }

  /// Obtains the current FCM registration token for this device.
  Future<String?> getDeviceToken() async {
    final getter = tokenGetter;
    if (getter != null) {
      return await getter();
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[NotificationService] Obtained FCM device token: $token');
      return token;
    } catch (e) {
      debugPrint('[NotificationService] Error obtaining FCM device token: $e');
      return null;
    }
  }

  /// Registers [token] with the backend via `POST /api/admin/fcm-token`.
  ///
  /// If [token] is omitted, attempts to obtain it via [getDeviceToken].
  /// Carries the admin JWT automatically via [ApiClient].
  Future<Result<String>> registerToken([String? token]) async {
    final tokenToRegister = token ?? await getDeviceToken();
    if (tokenToRegister == null || tokenToRegister.trim().isEmpty) {
      debugPrint('[NotificationService] Cannot register token: token is null or empty.');
      return const Result.failure(
        'FCM token is unavailable or empty.',
        errorCode: 'TOKEN_UNAVAILABLE',
      );
    }

    final trimmed = tokenToRegister.trim();

    try {
      debugPrint('[NotificationService] Registering FCM token with backend: $trimmed');
      final response = await _apiClient.dio.post<dynamic>(
        '/api/admin/fcm-token',
        data: {
          'token': trimmed,
        },
      );

      if (response.statusCode == 200) {
        _lastRegisteredToken = trimmed;
        debugPrint('[NotificationService] Successfully registered FCM token with backend.');
        return Result.success(trimmed);
      }

      return const Result.failure(
        'Unexpected response from server while registering FCM token.',
      );
    } on DioException catch (e) {
      debugPrint('[NotificationService] DioException while registering FCM token: $e');
      return ApiClient.failureFromDioException<String>(e);
    } catch (e) {
      debugPrint('[NotificationService] Unexpected error while registering FCM token: $e');
      return Result.failure('Unexpected error registering FCM token: $e');
    }
  }

  /// Sets up an automatic listener for FCM token rotation/refresh events.
  ///
  /// When a new token is issued by Firebase, registers it with the backend automatically.
  void listenForTokenRefresh() {
    _refreshSubscription?.cancel();

    try {
      final getter = tokenRefreshStreamGetter;
      final stream = getter != null
          ? getter()
          : FirebaseMessaging.instance.onTokenRefresh;

      _refreshSubscription = stream.listen((newToken) async {
        debugPrint('[NotificationService] FCM token refreshed: $newToken');
        await registerToken(newToken);
      }, onError: (Object err) {
        debugPrint('[NotificationService] Error in FCM onTokenRefresh stream: $err');
      });
    } catch (e) {
      debugPrint('[NotificationService] Could not listen to token refresh: $e');
    }
  }

  /// High-level workflow called right after successful login or session restoration:
  /// 1. Requests notification permission (prompts user if Android 13+)
  /// 2. Obtains current FCM token
  /// 3. Registers token with the backend
  /// 4. Starts listening for token rotation events
  Future<Result<String>> initializeAndRegister() async {
    await requestPermission();
    final result = await registerToken();
    listenForTokenRefresh();
    return result;
  }

  /// Disposes active subscriptions.
  void dispose() {
    _refreshSubscription?.cancel();
    _refreshSubscription = null;
    _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
    _messageOpenedAppSubscription?.cancel();
    _messageOpenedAppSubscription = null;
  }

  // --- Push-3 Message Handling & Deep Linking ---

  /// Sets up message listeners across foreground and background states,
  /// routing taps into [onNavigateToPendingOrders].
  ///
  /// Implements `ARCHITECTURE.md` §5.5, §6 and `PRD.md` §3.6 (A-33, A-34).
  void setupMessageHandlers({
    required void Function() onNavigateToPendingOrders,
    void Function(String title, String body)? onShowInAppSignal,
    void Function()? onOrderDataReceived,
  }) {
    _foregroundSubscription?.cancel();
    _messageOpenedAppSubscription?.cancel();

    // 1. Foreground messages: FirebaseMessaging.onMessage
    try {
      final fgStream = foregroundMessageStreamGetter != null
          ? foregroundMessageStreamGetter!()
          : FirebaseMessaging.onMessage;

      Future<void> handleMessage(RemoteMessage message) async {
        debugPrint(
          '[NotificationService] Foreground push received: ${message.messageId}',
        );

        // Always display notification through the custom channel to trigger the custom sound
        await showOrderNotification(message);

        final title = message.notification?.title ??
            message.data['title']?.toString() ??
            'New Order Placed';
        final body = message.notification?.body ??
            message.data['body']?.toString() ??
            'A new customer order has arrived.';

        if (onShowInAppSignal != null) {
          onShowInAppSignal(title, body);
        }

        if (onOrderDataReceived != null) {
          onOrderDataReceived();
        }
      }

      onSimulatedForegroundMessage = handleMessage;
      _foregroundSubscription = fgStream.listen(handleMessage);
    } catch (e) {
      debugPrint('[NotificationService] Error setting up onMessage listener: $e');
    }

    // 2. Background tap: FirebaseMessaging.onMessageOpenedApp
    try {
      final bgTapStream = messageOpenedAppStreamGetter != null
          ? messageOpenedAppStreamGetter!()
          : FirebaseMessaging.onMessageOpenedApp;

      _messageOpenedAppSubscription = bgTapStream.listen((message) {
        debugPrint(
          '[NotificationService] Notification tapped from background: ${message.messageId}',
        );
        onNavigateToPendingOrders();
      });
    } catch (e) {
      debugPrint(
        '[NotificationService] Error setting up onMessageOpenedApp listener: $e',
      );
    }
  }

  /// Checks whether the app was cold-started from a killed state by tapping a notification.
  /// If so, invokes [onNavigateToPendingOrders].
  Future<bool> checkInitialNotification({
    required void Function() onNavigateToPendingOrders,
  }) async {
    try {
      // 1. Check FCM initial message
      final getter = initialMessageGetter;
      final fcmInitialMessage = getter != null
          ? await getter()
          : await FirebaseMessaging.instance.getInitialMessage();

      if (fcmInitialMessage != null) {
        debugPrint(
          '[NotificationService] App launched from killed state via FCM notification: ${fcmInitialMessage.messageId}',
        );
        onNavigateToPendingOrders();
        return true;
      }

      // 2. Check local notifications launch details
      final launchGetter = initialLaunchGetter;
      if (launchGetter != null) {
        final didLaunch = await launchGetter();
        if (didLaunch) {
          debugPrint(
            '[NotificationService] App launched from killed state via local notification.',
          );
          onNavigateToPendingOrders();
          return true;
        }
      } else {
        final launchDetails =
            await localNotificationsPlugin.getNotificationAppLaunchDetails();
        if (launchDetails?.didNotificationLaunchApp == true) {
          debugPrint(
            '[NotificationService] App launched from killed state via local notification.',
          );
          onNavigateToPendingOrders();
          return true;
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Error checking initial notification: $e');
    }
    return false;
  }

  // --- Push-2 Channel Configuration ---

  /// The Android notification channel ID for new orders.
  static const String orderChannelId = 'sns_new_orders';

  /// The user-visible name of the channel in Android settings.
  static const String orderChannelName = 'New Orders';

  /// The user-visible description of the channel in Android settings.
  static const String orderChannelDescription =
      'Notifications for newly placed customer orders';

  /// The custom alert sound raw resource name (res/raw/order_alert.wav).
  static const String orderSoundResource = 'order_alert';

  static void Function()? _globalNotificationResponseHandler;
  static void Function(RemoteMessage)? onSimulatedForegroundMessage;

  /// Registers a global callback invoked when a local notification is tapped.
  static void setNotificationResponseHandler(void Function() handler) {
    _globalNotificationResponseHandler = handler;
  }

  /// Simulates an incoming foreground push message to test in-app banner and sound.
  static void triggerForegroundTest({
    String title = 'New Order #1042',
    String body = 'Dine-In • Table 3 • 2 items • ₹280',
  }) {
    final msg = RemoteMessage(
      messageId: 'test-fg-${DateTime.now().millisecondsSinceEpoch}',
      data: {'type': 'order_new', 'orderId': '1042'},
      notification: RemoteNotification(
        title: title,
        body: body,
      ),
    );
    onSimulatedForegroundMessage?.call(msg);
  }

  /// Triggers a high-importance local notification on the custom channel with sound.
  static Future<void> triggerBackgroundTest({
    String title = 'New Order #1043',
    String body = 'Takeaway • 1 item • ₹150',
  }) async {
    final msg = RemoteMessage(
      messageId: 'test-bg-${DateTime.now().millisecondsSinceEpoch}',
      data: {'type': 'order_new', 'orderId': '1043'},
      notification: RemoteNotification(
        title: title,
        body: body,
      ),
    );
    await showOrderNotification(msg);
  }

  /// High-importance Android notification channel with custom raw sound asset.
  ///
  /// Implements `PRD.md` §3.6 (A-32) and `ARCHITECTURE.md` §6.
  static const AndroidNotificationChannel orderChannel =
      AndroidNotificationChannel(
    orderChannelId,
    orderChannelName,
    description: orderChannelDescription,
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(orderSoundResource),
    enableVibration: true,
    showBadge: true,
  );

  /// Shared singleton instance for local notifications.
  static final FlutterLocalNotificationsPlugin localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes flutter_local_notifications and creates the custom high-importance
  /// Android notification channel.
  ///
  /// MUST be called unconditionally at app startup in [main.dart] before any
  /// notification can arrive (PRD §3.6 A-32).
  static Future<void> setupNotificationChannel({
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    try {
      final notifications = plugin ?? localNotificationsPlugin;
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint(
            '[NotificationService] Local notification tapped (payload: ${response.payload})',
          );
          _globalNotificationResponseHandler?.call();
        },
      );

      final androidPlugin = notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(orderChannel);
      debugPrint(
        '[NotificationService] Notification channel "${orderChannel.id}" created successfully.',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Error initializing local notifications or creating channel: $e',
      );
    }
  }

  /// Displays a local notification using [orderChannel] with the custom sound.
  static Future<void> showOrderNotification(
    RemoteMessage message, {
    FlutterLocalNotificationsPlugin? plugin,
  }) async {
    try {
      final title = message.notification?.title ??
          message.data['title']?.toString() ??
          'New Order Placed';
      final body = message.notification?.body ??
          message.data['body']?.toString() ??
          'A new customer order has arrived.';
      final orderId = message.data['orderId']?.toString();

      final notifications = plugin ?? FlutterLocalNotificationsPlugin();
      const androidDetails = AndroidNotificationDetails(
        orderChannelId,
        orderChannelName,
        channelDescription: orderChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(orderSoundResource),
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails);

      final notificationId = message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await notifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: orderId,
      );
      debugPrint('[NotificationService] Local notification shown for order: $orderId');
    } catch (e) {
      debugPrint('[NotificationService] Error showing order notification: $e');
    }
  }
}

/// Top-level background message handler required by Firebase Messaging.
///
/// Runs in an isolated background thread when the app is in the background or killed.
/// Must be annotated with `@pragma('vm:entry-point')`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  debugPrint(
    '[firebaseMessagingBackgroundHandler] Received background FCM message: ${message.messageId}',
  );

  // If the message is a data message (no automatic OS notification display),
  // post a local notification into the high-importance custom channel.
  if (message.notification == null && message.data.isNotEmpty) {
    await NotificationService.setupNotificationChannel();
    await NotificationService.showOrderNotification(message);
  }
}
