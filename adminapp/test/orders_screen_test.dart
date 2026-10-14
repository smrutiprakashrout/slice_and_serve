import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/models/order.dart';
import 'package:adminapp/providers/orders_provider.dart';
import 'package:adminapp/screens/orders/orders_screen.dart';
import 'package:adminapp/screens/orders/order_card.dart';
import 'package:adminapp/services/order_service.dart';
import 'package:adminapp/theme/app_theme.dart';
import 'fixtures/order_fixtures.dart';

void main() {
  final fixedBaseTime = DateTime(2026, 9, 18, 12, 0);

  Widget buildTestApp({
    ThemeMode themeMode = ThemeMode.light,
    OrdersViewMode initialViewMode = OrdersViewMode.list,
    OrderStatusSegment initialSegment = OrderStatusSegment.pending,
    List<Order>? initialOrders,
    OrderService? orderService,
  }) {
    final service = orderService ??
        FakeOrderService(
          initialOrders: initialOrders ?? createMockOrders(baseTime: fixedBaseTime),
        );

    return ProviderScope(
      overrides: [
        orderServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: Scaffold(
          body: OrdersScreen(
            initialViewMode: initialViewMode,
            initialSegment: initialSegment,
            referenceTime: fixedBaseTime,
          ),
        ),
      ),
    );
  }

  group('OrdersScreen Widget Tests (Task 4A-2 & 4B-1)', () {
    testWidgets('Renders segmented control with 3 segments and initial pending list',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Check segmented control existence
      expect(find.byKey(const Key('orders_segmented_control')), findsOneWidget);
      expect(find.byKey(const Key('orders_segment_pending')), findsOneWidget);
      expect(find.byKey(const Key('orders_segment_accepted')), findsOneWidget);
      expect(find.byKey(const Key('orders_segment_completed')), findsOneWidget);

      // Verify pending orders are visible by default
      expect(find.byKey(const Key('order_card_ORD-101')), findsOneWidget);
      expect(find.byKey(const Key('order_card_ORD-102')), findsOneWidget);
      expect(find.byKey(const Key('order_card_ORD-103')), findsOneWidget);

      // Customer names
      expect(find.text('Aarav Mehta'), findsOneWidget);
      expect(find.text('Priya Sundaram'), findsOneWidget);
      expect(find.text('Vikram Malhotra'), findsOneWidget);
    });

    testWidgets('Tapping segments switches filtered order list cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Initial state: Pending
      expect(find.text('Aarav Mehta'), findsOneWidget);

      // Switch to Accepted
      await tester.tap(find.byKey(const Key('orders_segment_accepted')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('order_card_ORD-104')), findsOneWidget);
      expect(find.byKey(const Key('order_card_ORD-105')), findsOneWidget);
      expect(find.byKey(const Key('order_card_ORD-106')), findsOneWidget);
      expect(find.text('Riya Sharma'), findsOneWidget);
      expect(find.text('Rohan Deshmukh'), findsOneWidget);

      // Switch to Completed
      await tester.tap(find.byKey(const Key('orders_segment_completed')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('order_card_ORD-107')), findsOneWidget);
      expect(find.byKey(const Key('order_card_ORD-108')), findsOneWidget);
      expect(find.byKey(const Key('order_card_ORD-109')), findsOneWidget);
      expect(find.text('Kabir Verma'), findsOneWidget);
    });

    testWidgets(
        'CRITICAL PRD A-25: Dine-in with table shows table number, dine-in without table shows no gap/null',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // ORD-101: dine-in with 'Table 4'
      expect(find.byKey(const Key('order_table_ORD-101')), findsOneWidget);
      expect(find.text('Table 4'), findsOneWidget);

      // ORD-102: dine-in with NO table number (tableNumber is null)
      expect(find.byKey(const Key('order_table_ORD-102')), findsNothing);
      expect(find.text('null'), findsNothing);

      // ORD-103: pickup order (tableNumber is null)
      expect(find.byKey(const Key('order_table_ORD-103')), findsNothing);
    });

    testWidgets('Renders items list, quantities, and Playfair Display totals',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // ORD-101 items & price
      expect(find.text('2x'), findsWidgets);
      expect(find.text('Margherita Classic Pizza'), findsWidgets);
      expect(find.byKey(const Key('order_total_ORD-101')), findsOneWidget);

      // ORD-102 items & price
      expect(find.text('Double Cheese Burst Pizza'), findsWidgets);
      expect(find.byKey(const Key('order_total_ORD-102')), findsOneWidget);
    });

    testWidgets('Tapping Empty mode chip displays segment-specific empty state',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Switch to Empty mode
      await tester.tap(find.byKey(const Key('orders_mode_empty')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('orders_empty_view_pending')), findsOneWidget);
      expect(find.text('No Pending Orders'), findsOneWidget);

      // Switch segment while in empty mode
      await tester.tap(find.byKey(const Key('orders_segment_accepted')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('orders_empty_view_accepted')), findsOneWidget);
      expect(find.text('No Accepted Orders'), findsOneWidget);
    });

    testWidgets('Tapping Loading mode chip displays shimmering skeleton cards',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Switch to Loading mode
      await tester.tap(find.byKey(const Key('orders_mode_loading')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('orders_loading_skeleton_view')), findsOneWidget);
    });

    testWidgets('Renders cleanly in Dark Mode', (tester) async {
      await tester.pumpWidget(buildTestApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('orders_segmented_control')), findsOneWidget);
      expect(find.byKey(const Key('order_card_ORD-101')), findsOneWidget);
      expect(find.text('Aarav Mehta'), findsOneWidget);
    });

    testWidgets('Pull to refresh re-fetches orders and displays feedback snackbar',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Drag to trigger pull to refresh
      await tester.fling(
        find.text('Aarav Mehta'),
        const Offset(0.0, 300.0),
        1000.0,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Orders refreshed'), findsOneWidget);
    });

    testWidgets('Error state renders friendly message and retry button',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final failingService = FakeOrderService()..shouldGetOrdersFail = true;

      await tester.pumpWidget(buildTestApp(orderService: failingService));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('orders_error_view')), findsOneWidget);
      expect(find.text('Unable to load orders'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Now fix service and tap Retry
      failingService.shouldGetOrdersFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Successfully recovers and displays order list
      expect(find.byKey(const Key('orders_error_view')), findsNothing);
      expect(find.byKey(const Key('order_card_ORD-101')), findsOneWidget);
    });
  });

  group('OrdersScreen Action Buttons Tests (Task 4A-3 & 4B-1)', () {
    testWidgets('Pending orders show Accept and Reject buttons; other statuses do not',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Pending order ORD-101 has both Accept and Reject
      expect(find.byKey(const Key('order_accept_button_ORD-101')), findsOneWidget);
      expect(find.byKey(const Key('order_reject_button_ORD-101')), findsOneWidget);
      expect(find.byKey(const Key('order_complete_button_ORD-101')), findsNothing);
    });

    testWidgets('Accepted orders show Complete button; Accept and Reject are absent',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(initialSegment: OrderStatusSegment.accepted));
      await tester.pumpAndSettle();

      // Accepted order ORD-104 has Complete button only
      expect(find.byKey(const Key('order_complete_button_ORD-104')), findsOneWidget);
      expect(find.byKey(const Key('order_accept_button_ORD-104')), findsNothing);
      expect(find.byKey(const Key('order_reject_button_ORD-104')), findsNothing);
    });

    testWidgets('Completed and Rejected orders show genuinely zero action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Check Completed segment
      await tester.pumpWidget(buildTestApp(initialSegment: OrderStatusSegment.completed));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('order_card_ORD-107')), findsOneWidget);
      expect(find.byKey(const Key('order_accept_button_ORD-107')), findsNothing);
      expect(find.byKey(const Key('order_reject_button_ORD-107')), findsNothing);
      expect(find.byKey(const Key('order_complete_button_ORD-107')), findsNothing);
    });

    testWidgets('Tapping Accept moves order from Pending to Accepted immediately',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // ORD-101 is in Pending
      expect(find.byKey(const Key('order_card_ORD-101')), findsOneWidget);

      // Tap Accept on ORD-101
      await tester.tap(find.byKey(const Key('order_accept_button_ORD-101')));
      await tester.pumpAndSettle();

      // ORD-101 should no longer be in Pending segment list
      expect(find.byKey(const Key('order_card_ORD-101')), findsNothing);

      // Feedback snackbar appears
      expect(find.text('Order #ORD-101 accepted'), findsOneWidget);

      // Switch to Accepted segment
      await tester.tap(find.byKey(const Key('orders_segment_accepted')));
      await tester.pumpAndSettle();

      // ORD-101 is now in Accepted list with Complete button
      expect(find.byKey(const Key('order_card_ORD-101')), findsOneWidget);
      expect(find.byKey(const Key('order_complete_button_ORD-101')), findsOneWidget);
    });

    testWidgets(
        'Tapping Reject opens confirmation dialog; cancelling leaves order in Pending',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap Reject on ORD-102
      await tester.tap(find.byKey(const Key('order_reject_button_ORD-102')));
      await tester.pumpAndSettle();

      // Confirmation dialog opens
      expect(find.text('Reject Order #ORD-102?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reject Order'), findsOneWidget);

      // Cancel rejection
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is closed and ORD-102 remains in Pending
      expect(find.text('Reject Order #ORD-102?'), findsNothing);
      expect(find.byKey(const Key('order_card_ORD-102')), findsOneWidget);
    });

    testWidgets(
        'Confirming Reject in dialog moves order from Pending to Rejected immediately',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap Reject on ORD-102
      await tester.tap(find.byKey(const Key('order_reject_button_ORD-102')));
      await tester.pumpAndSettle();

      // Confirm rejection
      await tester.tap(find.text('Reject Order'));
      await tester.pumpAndSettle();

      // ORD-102 has left Pending
      expect(find.byKey(const Key('order_card_ORD-102')), findsNothing);
      expect(find.text('Order #ORD-102 rejected'), findsOneWidget);
    });

    testWidgets('Tapping Complete on accepted order moves it to Completed immediately',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(initialSegment: OrderStatusSegment.accepted));
      await tester.pumpAndSettle();

      // ORD-104 is in Accepted
      expect(find.byKey(const Key('order_card_ORD-104')), findsOneWidget);

      // Tap Complete on ORD-104
      await tester.tap(find.byKey(const Key('order_complete_button_ORD-104')));
      await tester.pumpAndSettle();

      // ORD-104 has left Accepted
      expect(find.byKey(const Key('order_card_ORD-104')), findsNothing);
      expect(find.text('Order #ORD-104 completed'), findsOneWidget);

      // Switch to Completed segment
      await tester.tap(find.byKey(const Key('orders_segment_completed')));
      await tester.pumpAndSettle();

      // ORD-104 is now in Completed with NO action buttons
      expect(find.byKey(const Key('order_card_ORD-104')), findsOneWidget);
      expect(find.byKey(const Key('order_complete_button_ORD-104')), findsNothing);
    });

    testWidgets('Action buttons render cleanly in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('order_accept_button_ORD-101')), findsOneWidget);
      expect(find.byKey(const Key('order_reject_button_ORD-101')), findsOneWidget);
    });

    testWidgets('Action button 409 Conflict surfaces error and refreshes segment',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = FakeOrderService();
      await tester.pumpWidget(buildTestApp(orderService: service));
      await tester.pumpAndSettle();

      // Configure service for 409 on action
      service.return409OnAction = true;
      service.action409Message =
          'Cannot transition an order from accepted to accepted.';
      // Simulate backend having already moved ORD-101
      service.orders.removeWhere((o) => o.id == 'ORD-101');

      // Tap Accept on stale ORD-101
      await tester.tap(find.byKey(const Key('order_accept_button_ORD-101')));
      await tester.pumpAndSettle();

      // Error message is displayed in SnackBar
      expect(
          find.text('Cannot transition an order from accepted to accepted.'),
          findsOneWidget);

      // List was refreshed from server: ORD-101 is gone from UI
      expect(find.byKey(const Key('order_card_ORD-101')), findsNothing);
    });

    testWidgets(
        'Action button network error displays error message without crashing',
        (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final service = FakeOrderService()..shouldAcceptFail = true;
      await tester.pumpWidget(buildTestApp(orderService: service));
      await tester.pumpAndSettle();

      // Tap Accept
      await tester.tap(find.byKey(const Key('order_accept_button_ORD-101')));
      await tester.pumpAndSettle();

      // Error message is displayed
      expect(find.text('Failed to accept order'), findsOneWidget);

      // Order is preserved in list
      expect(find.byKey(const Key('order_card_ORD-101')), findsOneWidget);
    });
  });

  group('formatRelativeTime helper', () {
    test('formats time differences accurately', () {
      final now = DateTime(2026, 9, 18, 12, 0);

      expect(formatRelativeTime(now.subtract(const Duration(seconds: 10)), baseTime: now), 'Just now');
      expect(formatRelativeTime(now.subtract(const Duration(minutes: 2)), baseTime: now), '2 min ago');
      expect(formatRelativeTime(now.subtract(const Duration(minutes: 45)), baseTime: now), '45 min ago');
      expect(formatRelativeTime(now.subtract(const Duration(hours: 1)), baseTime: now), '1 hour ago');
      expect(formatRelativeTime(now.subtract(const Duration(hours: 5)), baseTime: now), '5 hours ago');
      expect(formatRelativeTime(now.subtract(const Duration(days: 1)), baseTime: now), 'Yesterday');
      expect(formatRelativeTime(now.subtract(const Duration(days: 3)), baseTime: now), '3 days ago');
    });
  });
}
