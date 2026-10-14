import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/core/result.dart';
import 'package:adminapp/models/order.dart';
import 'package:adminapp/providers/orders_provider.dart';
import 'fixtures/order_fixtures.dart';

void main() {
  group('OrdersProvider (Task 4B-1)', () {
    late FakeOrderService fakeService;
    late ProviderContainer container;

    setUp(() {
      fakeService = FakeOrderService();
      container = ProviderContainer(
        overrides: [
          orderServiceProvider.overrideWithValue(fakeService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial build loads pending orders from FakeOrderService', () async {
      final listener = container.listen(ordersProvider, (_, _) {});
      addTearDown(listener.close);

      // Initially in loading or loaded
      final initialOrders = await container.read(ordersProvider.future);

      expect(initialOrders.isNotEmpty, isTrue);
      expect(initialOrders.every((o) => o.status == 'pending'), isTrue);
      expect(initialOrders.length, 3);
    });

    test('fetchSegment loads orders for accepted segment', () async {
      final notifier = container.read(ordersProvider.notifier);

      await notifier.fetchSegment(OrderStatusSegment.accepted);
      final acceptedOrders = await container.read(ordersProvider.future);

      expect(acceptedOrders.isNotEmpty, isTrue);
      expect(acceptedOrders.every((o) => o.status == 'accepted'), isTrue);
      expect(acceptedOrders.length, 3);
    });

    test('refresh re-fetches orders for current segment', () async {
      final notifier = container.read(ordersProvider.notifier);

      await notifier.fetchSegment(OrderStatusSegment.pending);
      await notifier.refresh();

      final orders = await container.read(ordersProvider.future);
      expect(orders.length, 3);
    });

    test('updateOrderStatusLocally removes order from pending and updates target', () async {
      final notifier = container.read(ordersProvider.notifier);
      final pendingOrders = await container.read(ordersProvider.future);
      final firstOrder = pendingOrders.first;

      // Update to accepted locally
      notifier.updateOrderStatusLocally(firstOrder, 'accepted');

      final updatedPending = container.read(ordersProvider).value!;
      expect(updatedPending.any((o) => o.id == firstOrder.id), isFalse);

      // Switch to accepted segment
      await notifier.fetchSegment(OrderStatusSegment.accepted);
      final acceptedOrders = container.read(ordersProvider).value!;
      expect(acceptedOrders.any((o) => o.id == firstOrder.id), isTrue);
    });

    test('Defensively filters out rejected orders', () async {
      // Add a rejected order to fakeService
      fakeService.orders.add(
        Order(
          id: 'REJECTED-1',
          customerName: 'Rejected Customer',
          fulfillment: 'dine-in',
          items: const [],
          total: 50.0,
          status: 'rejected',
          placedAt: DateTime.now(),
        ),
      );

      final notifier = container.read(ordersProvider.notifier);
      await notifier.refresh();

      final orders = container.read(ordersProvider).value!;
      expect(orders.any((o) => o.status == 'rejected'), isFalse);
    });

    test('acceptOrder calls service, moves order to accepted, and removes from pending', () async {
      final notifier = container.read(ordersProvider.notifier);
      await notifier.fetchSegment(OrderStatusSegment.accepted);
      await notifier.fetchSegment(OrderStatusSegment.pending);
      final pendingOrders = container.read(ordersProvider).value!;
      final first = pendingOrders.first;

      final result = await notifier.acceptOrder(first.id);

      expect(result.isSuccess, isTrue);
      // Order is removed from current pending list
      final updatedPending = container.read(ordersProvider).value!;
      expect(updatedPending.any((o) => o.id == first.id), isFalse);

      // Order is in accepted segment cache
      expect(notifier.countForSegment(OrderStatusSegment.accepted), 4);
    });

    test('rejectOrder calls service and removes order entirely from all segments', () async {
      final notifier = container.read(ordersProvider.notifier);
      await notifier.fetchSegment(OrderStatusSegment.completed);
      await notifier.fetchSegment(OrderStatusSegment.accepted);
      await notifier.fetchSegment(OrderStatusSegment.pending);
      final pendingOrders = container.read(ordersProvider).value!;
      final second = pendingOrders[1];

      final result = await notifier.rejectOrder(second.id);

      expect(result.isSuccess, isTrue);
      // Order is removed from pending
      final updatedPending = container.read(ordersProvider).value!;
      expect(updatedPending.any((o) => o.id == second.id), isFalse);

      // Order is not in any segment cache
      expect(notifier.countForSegment(OrderStatusSegment.pending), 2);
      expect(notifier.countForSegment(OrderStatusSegment.accepted), 3);
      expect(notifier.countForSegment(OrderStatusSegment.completed), 3);
    });

    test('completeOrder calls service, removes from accepted, and adds to completed cache', () async {
      final notifier = container.read(ordersProvider.notifier);
      await notifier.fetchSegment(OrderStatusSegment.completed);
      await notifier.fetchSegment(OrderStatusSegment.accepted);
      final acceptedOrders = container.read(ordersProvider).value!;
      final first = acceptedOrders.first;

      final result = await notifier.completeOrder(first.id);

      expect(result.isSuccess, isTrue);
      // Removed from accepted
      final updatedAccepted = container.read(ordersProvider).value!;
      expect(updatedAccepted.any((o) => o.id == first.id), isFalse);

      // Added to completed cache
      expect(notifier.countForSegment(OrderStatusSegment.completed), 4);
    });

    test('acceptOrder on 409 Conflict triggers refresh and returns failure with clear error', () async {
      fakeService.return409OnAction = true;
      fakeService.action409Message = 'Cannot transition an order from accepted to accepted.';

      final notifier = container.read(ordersProvider.notifier);
      final pendingOrders = await container.read(ordersProvider.future);
      final first = pendingOrders.first;

      // Simulate order having moved in backend
      fakeService.orders.removeWhere((o) => o.id == first.id);

      final result = await notifier.acceptOrder(first.id);

      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.statusCode, 409);
      expect(failure.errorMessage, 'Cannot transition an order from accepted to accepted.');

      // PRD A-29 [B]: List was refreshed to reflect reality
      final refreshedList = container.read(ordersProvider).value!;
      expect(refreshedList.any((o) => o.id == first.id), isFalse);
    });

    test('Action on 500 network error preserves current list and returns failure', () async {
      fakeService.shouldAcceptFail = true;

      final notifier = container.read(ordersProvider.notifier);
      final pendingOrders = await container.read(ordersProvider.future);
      final first = pendingOrders.first;

      final result = await notifier.acceptOrder(first.id);

      expect(result.isFailure, isTrue);
      // Item is still preserved in the pending list
      final currentList = container.read(ordersProvider).value!;
      expect(currentList.any((o) => o.id == first.id), isTrue);
    });

    test('pendingOrdersCountProvider exposes real pending count initially and decrements on action (Task 4B-3)', () async {
      final listener = container.listen(ordersProvider, (_, _) {});
      addTearDown(listener.close);

      // Wait for build to load
      await container.read(ordersProvider.future);

      // Initial count from fakeService is 3
      expect(container.read(pendingOrdersCountProvider), 3);

      final notifier = container.read(ordersProvider.notifier);
      final pendingOrders = container.read(ordersProvider).value!;
      final first = pendingOrders.first;

      // Accept first order
      await notifier.acceptOrder(first.id);

      // Count immediately decrements to 2
      expect(container.read(pendingOrdersCountProvider), 2);

      // Reject second order
      final second = pendingOrders[1];
      await notifier.rejectOrder(second.id);

      // Count decrements to 1
      expect(container.read(pendingOrdersCountProvider), 1);
    });

    test('pendingOrdersCountProvider retains accurate count when switching segments (Task 4B-3)', () async {
      final listener = container.listen(ordersProvider, (_, _) {});
      addTearDown(listener.close);

      await container.read(ordersProvider.future);
      expect(container.read(pendingOrdersCountProvider), 3);

      final notifier = container.read(ordersProvider.notifier);
      await notifier.fetchSegment(OrderStatusSegment.accepted);

      // Active segment is now accepted, but pending count provider still reports cached pending count 3
      expect(notifier.currentSegment, OrderStatusSegment.accepted);
      expect(container.read(pendingOrdersCountProvider), 3);
    });

    test('refreshOnTabVisit refreshes orders and silent pending count (Task 4B-3)', () async {
      final listener = container.listen(ordersProvider, (_, _) {});
      addTearDown(listener.close);

      await container.read(ordersProvider.future);

      final notifier = container.read(ordersProvider.notifier);
      await notifier.fetchSegment(OrderStatusSegment.accepted);

      // Add a new pending order directly to fake service to simulate external backend change
      fakeService.orders.add(
        Order(
          id: 'EXTERNAL-1',
          customerName: 'External Customer',
          fulfillment: 'pickup',
          items: const [],
          total: 100.0,
          status: 'pending',
          placedAt: DateTime.now(),
        ),
      );

      // User visits tab while on accepted segment
      await notifier.refreshOnTabVisit();

      // Pending count provider reflects updated count (3 + 1 = 4)
      expect(container.read(pendingOrdersCountProvider), 4);
    });
  });
}
