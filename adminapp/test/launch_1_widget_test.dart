import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:adminapp/core/result.dart';
import 'package:adminapp/models/loyalty_card.dart';
import 'package:adminapp/models/menu_item.dart';
import 'package:adminapp/providers/auth_provider.dart';
import 'package:adminapp/providers/loyalty_provider.dart';
import 'package:adminapp/providers/menu_provider.dart';
import 'package:adminapp/providers/orders_provider.dart';
import 'package:adminapp/screens/login_screen.dart';
import 'package:adminapp/screens/loyalty/loyalty_scanner_screen.dart';
import 'package:adminapp/screens/menu/menu_screen.dart';
import 'package:adminapp/screens/orders/orders_screen.dart';
import 'package:adminapp/services/auth_service.dart';
import 'package:adminapp/services/loyalty_service.dart';
import 'package:adminapp/services/menu_service.dart';
import 'package:adminapp/services/order_service.dart';
import 'package:adminapp/theme/app_theme.dart';
import 'package:adminapp/widgets/brand_button.dart';

import 'fixtures/loyalty_fixtures.dart';
import 'fixtures/menu_fixtures.dart';
import 'fixtures/order_fixtures.dart';

// =============================================================================
// MOCK SERVICES FOR LAUNCH-1 WIDGET TESTS
// =============================================================================

class MockAuthService implements AuthService {
  Future<Result<String>> Function(String username, String password)? onLogin;
  bool sessionActive = false;

  @override
  Future<Result<String>> login(String username, String password) async {
    if (onLogin != null) {
      return onLogin!(username, password);
    }
    return const Result.success('mock_jwt_token_123');
  }

  @override
  Future<bool> hasValidSession() async => sessionActive;

  @override
  Future<void> logout() async {
    sessionActive = false;
  }
}

class MockMenuService extends FakeMenuService {
  Future<Result<MenuItem>> Function(String id, bool available)?
      customSetAvailabilityHandler;

  MockMenuService({
    super.shouldSetAvailabilityFail,
    super.setAvailabilityErrorMessage,
  });

  @override
  Future<Result<MenuItem>> setAvailability(String itemId, bool available) async {
    if (customSetAvailabilityHandler != null) {
      return customSetAvailabilityHandler!(itemId, available);
    }
    return super.setAvailability(itemId, available);
  }
}

class MockLoyaltyService extends LoyaltyService {
  Result<LoyaltyScanResult>? nextScanResult;
  String? lastStampedCustomerId;
  String? lastRedeemedCustomerId;

  MockLoyaltyService({this.nextScanResult});

  @override
  Future<Result<LoyaltyScanResult>> scanToken(String token) async {
    if (nextScanResult != null) {
      return nextScanResult!;
    }
    return const Result.success(testScanStampInProgress);
  }

  @override
  Future<Result<LoyaltyScanResult>> addStamp(
    String customerId, {
    LoyaltyScanResult? currentResult,
  }) async {
    lastStampedCustomerId = customerId;
    return Result.success(
      (currentResult ?? testScanStampInProgress).copyWith(
        stamps: (currentResult?.stamps ?? 0) + 1,
      ),
    );
  }

  @override
  Future<Result<LoyaltyScanResult>> redeemReward(
    String customerId, {
    LoyaltyScanResult? currentResult,
  }) async {
    lastRedeemedCustomerId = customerId;
    return Result.success(
      (currentResult ?? testScanRedeemReady).copyWith(
        stamps: 0,
        rewardReady: false,
      ),
    );
  }
}

// =============================================================================
// LAUNCH-1 TEST SUITE
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // 1. LOGIN SCREEN WIDGET TESTS
  // ---------------------------------------------------------------------------
  group('Launch-1 · 1. Login Screen Widget Tests', () {
    Widget buildLoginApp({
      required MockAuthService authService,
      VoidCallback? onLoginSuccess,
    }) {
      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
          menuServiceProvider.overrideWithValue(FakeMenuService()),
          orderServiceProvider.overrideWithValue(FakeOrderService()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: LoginScreen(onLoginSuccess: onLoginSuccess),
        ),
      );
    }

    testWidgets('Empty fields do not allow submission and show validation error',
        (tester) async {
      final mockAuth = MockAuthService();
      var loginCalled = false;
      mockAuth.onLogin = (u, p) async {
        loginCalled = true;
        return const Result.success('token');
      };

      await tester.pumpWidget(buildLoginApp(authService: mockAuth));
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('login_submit_button'));

      // Both fields empty -> tap submit
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(loginCalled, isFalse);
      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.text('Please enter your username.'), findsOneWidget);

      // Fill username, leave password empty -> tap submit
      await tester.enterText(
          find.byKey(const Key('login_username_field')), 'admin');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(loginCalled, isFalse);
      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets(
        'Entering valid-looking credentials and tapping submit shows loading state',
        (tester) async {
      final completer = Completer<Result<String>>();
      final mockAuth = MockAuthService();
      mockAuth.onLogin = (u, p) => completer.future;

      var loginSuccessCalled = false;
      await tester.pumpWidget(buildLoginApp(
        authService: mockAuth,
        onLoginSuccess: () => loginSuccessCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('login_username_field')), 'serferaz');
      await tester.enterText(
          find.byKey(const Key('login_password_field')), 'secret123');

      final submitFinder = find.byKey(const Key('login_submit_button'));
      await tester.tap(submitFinder);

      // Loading state is immediately triggered on the BrandButton
      await tester.pump(const Duration(milliseconds: 20));
      final buttonBefore = tester.widget<BrandButton>(submitFinder);
      expect(buttonBefore.isLoading, isTrue);

      // Resolve the login future
      completer.complete(const Result.success('valid_token'));
      await tester.pumpAndSettle();

      expect(loginSuccessCalled, isTrue);
    });

    testWidgets(
        'Failed login shows inline error state with appropriate message without hitting real network',
        (tester) async {
      final mockAuth = MockAuthService();
      mockAuth.onLogin = (u, p) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Result.failure(
          'Invalid username or password. Please try again.',
          statusCode: 401,
          errorCode: 'INVALID_CREDENTIALS',
        );
      };

      await tester.pumpWidget(buildLoginApp(authService: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('login_username_field')), 'admin');
      await tester.enterText(
          find.byKey(const Key('login_password_field')), 'wrongpassword');

      final submitFinder = find.byKey(const Key('login_submit_button'));
      await tester.tap(submitFinder);

      // Advance through loading
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.widget<BrandButton>(submitFinder).isLoading, isTrue);

      // Finish failed login
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();

      // Verify inline error banner is rendered with the exact message
      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(
        find.text('Invalid username or password. Please try again.'),
        findsOneWidget,
      );
      expect(tester.widget<BrandButton>(submitFinder).isLoading, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. MENU AVAILABILITY TOGGLE WIDGET TESTS
  // ---------------------------------------------------------------------------
  group('Launch-1 · 2. Menu Availability Toggle Widget Tests', () {
    Widget buildMenuApp({required MenuService menuService}) {
      return ProviderScope(
        overrides: [
          menuServiceProvider.overrideWithValue(menuService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: MenuScreen(),
          ),
        ),
      );
    }

    testWidgets(
        'Tapping availability switch immediately reflects new state (optimistic update)',
        (tester) async {
      final completer = Completer<Result<MenuItem>>();
      final fakeMenu = MockMenuService();
      fakeMenu.customSetAvailabilityHandler = (id, available) => completer.future;

      await tester.pumpWidget(buildMenuApp(menuService: fakeMenu));
      await tester.pumpAndSettle();

      // menu-1 (Margherita Classic Pizza) is initially available: true
      final switchFinder = find.byKey(const Key('menu_switch_menu-1'));
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // Tap switch to toggle off
      await tester.tap(switchFinder);

      // Immediately after tap (before network future completes), state is optimistically updated
      await tester.pump();
      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      // Resolve background call
      final updatedItem = testMenuItems.first.copyWith(available: false);
      completer.complete(Result.success(updatedItem));
      await tester.pumpAndSettle();

      // Final state remains false
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
    });

    testWidgets(
        'Mocked failed API response reverts switch to prior state (rollback behavior)',
        (tester) async {
      final fakeMenu = FakeMenuService(
        shouldSetAvailabilityFail: true,
        setAvailabilityErrorMessage: 'Network timeout connecting to menu server.',
      );

      await tester.pumpWidget(buildMenuApp(menuService: fakeMenu));
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('menu_switch_menu-1'));
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // Tap switch to toggle off
      await tester.tap(switchFinder);

      // Wait for async call to reject and state to reconcile
      await tester.pumpAndSettle();

      // Switch must have rolled back to true
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      // Branded error snackbar notifies user of the rollback
      expect(
        find.text('Failed to update availability: Network timeout connecting to menu server.'),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 3. ORDER ACTION BUTTONS WIDGET TESTS
  // ---------------------------------------------------------------------------
  group('Launch-1 · 3. Order Action Buttons Widget Tests', () {
    final testTime = DateTime(2026, 9, 18, 12, 0);

    Widget buildOrdersApp({
      required OrderService orderService,
      OrderStatusSegment initialSegment = OrderStatusSegment.pending,
    }) {
      return ProviderScope(
        overrides: [
          orderServiceProvider.overrideWithValue(orderService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: OrdersScreen(
              initialSegment: initialSegment,
              referenceTime: testTime,
            ),
          ),
        ),
      );
    }

    testWidgets(
        'Pending shows Accept and Reject; Preparing shows only Complete; Completed shows none',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeOrderService = FakeOrderService(
        initialOrders: createMockOrders(baseTime: testTime),
      );

      // --- Pending Segment ---
      await tester.pumpWidget(buildOrdersApp(
        orderService: fakeOrderService,
        initialSegment: OrderStatusSegment.pending,
      ));
      await tester.pumpAndSettle();

      // ORD-101 (Pending): shows Accept and Reject, NO Complete
      expect(find.byKey(const Key('order_accept_button_ORD-101')), findsOneWidget);
      expect(find.byKey(const Key('order_reject_button_ORD-101')), findsOneWidget);
      expect(find.byKey(const Key('order_complete_button_ORD-101')), findsNothing);

      // --- Preparing / Accepted Segment ---
      await tester.tap(find.byKey(const Key('orders_segment_accepted')));
      await tester.pumpAndSettle();

      // ORD-104 (Accepted/Preparing): shows only Complete, NO Accept or Reject
      expect(find.byKey(const Key('order_complete_button_ORD-104')), findsOneWidget);
      expect(find.byKey(const Key('order_accept_button_ORD-104')), findsNothing);
      expect(find.byKey(const Key('order_reject_button_ORD-104')), findsNothing);

      // --- Completed Segment ---
      await tester.tap(find.byKey(const Key('orders_segment_completed')));
      await tester.pumpAndSettle();

      // ORD-107 (Completed): shows genuinely zero action buttons
      expect(find.byKey(const Key('order_card_ORD-107')), findsOneWidget);
      expect(find.byKey(const Key('order_accept_button_ORD-107')), findsNothing);
      expect(find.byKey(const Key('order_reject_button_ORD-107')), findsNothing);
      expect(find.byKey(const Key('order_complete_button_ORD-107')), findsNothing);
    });

    testWidgets(
        'Tapping Reject opens confirmation dialog; cancelling leaves order in Pending, confirming rejects it',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeOrderService = FakeOrderService(
        initialOrders: createMockOrders(baseTime: testTime),
      );

      await tester.pumpWidget(buildOrdersApp(
        orderService: fakeOrderService,
        initialSegment: OrderStatusSegment.pending,
      ));
      await tester.pumpAndSettle();

      // ORD-102 is initially in Pending
      expect(find.byKey(const Key('order_card_ORD-102')), findsOneWidget);

      // Tap Reject button on ORD-102
      await tester.tap(find.byKey(const Key('order_reject_button_ORD-102')));
      await tester.pumpAndSettle();

      // 1. Confirm dialog is open with title, Cancel, and Reject Order actions
      expect(find.text('Reject Order #ORD-102?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reject Order'), findsOneWidget);

      // 2. Tap Cancel -> dialog closes, order remains in Pending
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Reject Order #ORD-102?'), findsNothing);
      expect(find.byKey(const Key('order_card_ORD-102')), findsOneWidget);

      // 3. Tap Reject again and Confirm
      await tester.tap(find.byKey(const Key('order_reject_button_ORD-102')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reject Order'));
      await tester.pumpAndSettle();

      // Order is rejected and removed from Pending segment
      expect(find.byKey(const Key('order_card_ORD-102')), findsNothing);
      expect(find.text('Order #ORD-102 rejected'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. LOYALTY MODE-MISMATCH GUARD WIDGET TESTS
  // ---------------------------------------------------------------------------
  group('Launch-1 · 4. Loyalty Mode-Mismatch Guard Widget Tests', () {
    Widget buildLoyaltyApp({
      required LoyaltyService loyaltyService,
      LoyaltyScanMode initialMode = LoyaltyScanMode.stamp,
    }) {
      return ProviderScope(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(loyaltyService),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: LoyaltyScannerScreen(
              initialMode: initialMode,
            ),
          ),
        ),
      );
    }

    testWidgets(
        'Scanning Redeem token in Stamp mode: no result card, mismatch error renders, mode unchanged',
        (tester) async {
      // Mock scan returns an action of "redeem", but scanner is in "stamp" mode
      final mockLoyalty = MockLoyaltyService(
        nextScanResult: const Result.success(testScanMismatchRedeemOnStamp),
      );

      await tester.pumpWidget(buildLoyaltyApp(
        loyaltyService: mockLoyalty,
        initialMode: LoyaltyScanMode.stamp,
      ));
      await tester.pumpAndSettle();

      // Initial state: Stamp mode instruction visible
      expect(find.text('Scan to Add Stamp'), findsOneWidget);

      // Simulate camera detecting a QR code with a redeem payload
      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      mobileScanner.onDetect?.call(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'cust_redeem_qr_payload')],
        ),
      );
      await tester.pumpAndSettle();

      // Assert 1: Result card is NEVER rendered on mode mismatch
      expect(find.byKey(const Key('loyalty_result_card_view')), findsNothing);
      expect(find.byKey(const Key('loyalty_stamp_confirmation_card')), findsNothing);
      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')), findsNothing);

      // Assert 2: Mode mismatch error state DOES render with plain-language explanation
      expect(find.byKey(const Key('loyalty_mismatch_error_view')), findsOneWidget);
      expect(find.text('Redeem Code Scanned'), findsOneWidget);
      expect(
        find.text('This code is for redeeming a reward, not adding a stamp.'),
        findsOneWidget,
      );

      // Assert 3: Selected mode is UNCHANGED (still Stamp mode, never auto-switched)
      final closeBtn = find.byKey(const Key('loyalty_mismatch_close_button'));
      await tester.ensureVisible(closeBtn);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_mismatch_error_view')), findsNothing);
      expect(find.text('Scan to Add Stamp'), findsOneWidget);
      expect(find.text('Scan to Redeem Reward'), findsNothing);
    });

    testWidgets(
        'Scanning Stamp token in Redeem mode: no result card, mismatch error renders, mode unchanged',
        (tester) async {
      // Mock scan returns an action of "stamp", but scanner is in "redeem" mode
      final mockLoyalty = MockLoyaltyService(
        nextScanResult: const Result.success(testScanMismatchStampOnRedeem),
      );

      await tester.pumpWidget(buildLoyaltyApp(
        loyaltyService: mockLoyalty,
        initialMode: LoyaltyScanMode.redeem,
      ));
      await tester.pumpAndSettle();

      // Initial state: Redeem mode instruction visible
      expect(find.text('Scan to Redeem Reward'), findsOneWidget);

      // Simulate camera detecting a QR code with a stamp payload
      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      mobileScanner.onDetect?.call(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'cust_stamp_qr_payload')],
        ),
      );
      await tester.pumpAndSettle();

      // Assert 1: Result card is NEVER rendered on mode mismatch
      expect(find.byKey(const Key('loyalty_result_card_view')), findsNothing);
      expect(find.byKey(const Key('loyalty_stamp_confirmation_card')), findsNothing);
      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')), findsNothing);

      // Assert 2: Mode mismatch error state DOES render with plain-language explanation
      expect(find.byKey(const Key('loyalty_mismatch_error_view')), findsOneWidget);
      expect(find.text('Stamp Code Scanned'), findsOneWidget);
      expect(
        find.text('This code is for adding a stamp, not redeeming.'),
        findsOneWidget,
      );

      // Assert 3: Selected mode is UNCHANGED (still Redeem mode, never auto-switched)
      final closeBtn = find.byKey(const Key('loyalty_mismatch_close_button'));
      await tester.ensureVisible(closeBtn);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_mismatch_error_view')), findsNothing);
      expect(find.text('Scan to Redeem Reward'), findsOneWidget);
      expect(find.text('Scan to Add Stamp'), findsNothing);
    });
  });
}
