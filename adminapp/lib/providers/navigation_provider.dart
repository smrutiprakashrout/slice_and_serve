import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import 'orders_provider.dart';

/// Notifier managing the active tab index in [MainShell]:
/// - 0: Menu
/// - 1: Loyalty
/// - 2: Orders
/// - 3: Settings
class ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index.clamp(0, 3);
  }
}

/// Provider for the active tab index in [MainShell].
final shellTabProvider =
    NotifierProvider<ShellTabNotifier, int>(ShellTabNotifier.new);

/// Notifier managing the active segment in [OrdersScreen]:
/// - [OrderStatusSegment.pending]
/// - [OrderStatusSegment.preparing]
/// - [OrderStatusSegment.completed]
class OrdersSegmentNotifier extends Notifier<OrderStatusSegment> {
  @override
  OrderStatusSegment build() => OrderStatusSegment.pending;

  void setSegment(OrderStatusSegment segment) {
    state = segment;
  }
}

/// Provider for the active segment in [OrdersScreen].
final ordersSelectedSegmentProvider =
    NotifierProvider<OrdersSegmentNotifier, OrderStatusSegment>(
  OrdersSegmentNotifier.new,
);

/// Navigates the app to the Orders tab (index 2) and selects the Pending segment.
///
/// Automatically fetches the latest orders for the Pending segment and refreshes
/// the pending badge count.
///
/// Implements `ARCHITECTURE.md` §5.5, §6, `PRD.md` §3.6 (A-34), and `TASKS.md` Push-3.
void navigateToOrdersPending(WidgetRef ref) {
  // 1. Switch active bottom-navigation tab to Orders
  ref.read(shellTabProvider.notifier).setTab(2);

  // 2. Select the Pending segment
  ref.read(ordersSelectedSegmentProvider.notifier).setSegment(
        OrderStatusSegment.pending,
      );

  // 3. Fetch latest pending orders and refresh tab visit state
  ref.read(ordersProvider.notifier).fetchSegment(OrderStatusSegment.pending);
  ref.read(ordersProvider.notifier).refreshOnTabVisit();
}
