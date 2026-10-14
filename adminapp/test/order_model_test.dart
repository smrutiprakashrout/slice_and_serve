import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/models/order.dart';
import 'fixtures/order_fixtures.dart';

void main() {
  group('Order & OrderItem Models (Tasks 4A-1 & 4B-1)', () {
    test('OrderItem correctly computes line total and equality', () {
      const item1 = OrderItem(
        name: 'Margherita Classic Pizza',
        quantity: 2,
        price: 249.0,
      );
      const item2 = OrderItem(
        name: 'Margherita Classic Pizza',
        quantity: 2,
        price: 249.0,
      );
      const item3 = OrderItem(
        name: 'Margherita Classic Pizza',
        quantity: 1,
        price: 249.0,
      );

      expect(item1.lineTotal, 498.0);
      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
      expect(item1, isNot(equals(item3)));
    });

    test('OrderItem fromJson and toJson serialize and deserialize correctly', () {
      final json = {
        'name': 'Chicken 65 Sandwich',
        'quantity': 3,
        'price': 65.0,
        'menuItemId': 'menu-item-123',
      };

      final item = OrderItem.fromJson(json);
      expect(item.name, 'Chicken 65 Sandwich');
      expect(item.quantity, 3);
      expect(item.price, 65.0);
      expect(item.menuItemId, 'menu-item-123');

      final serialized = item.toJson();
      expect(serialized['name'], 'Chicken 65 Sandwich');
      expect(serialized['quantity'], 3);
      expect(serialized['price'], 65.0);
      expect(serialized['menuItemId'], 'menu-item-123');
    });

    test('Order getters and totalItemCount function accurately', () {
      final order = Order(
        id: 'ORD-TEST-1',
        customerName: 'Test Customer',
        fulfillment: 'dine-in',
        tableNumber: 'Table 5',
        items: const [
          OrderItem(name: 'Pizza', quantity: 2, price: 300.0),
          OrderItem(name: 'Drink', quantity: 3, price: 100.0),
        ],
        total: 900.0,
        status: 'pending',
        placedAt: DateTime(2026, 9, 18, 10, 0),
      );

      expect(order.isDineIn, isTrue);
      expect(order.isPickup, isFalse);
      expect(order.isPending, isTrue);
      expect(order.isAccepted, isFalse);
      expect(order.isCompleted, isFalse);
      expect(order.isRejected, isFalse);
      expect(order.totalItemCount, 5);
      expect(order.tableNumber, 'Table 5');
    });

    test('Order copyWith allows modifying fields and clearing tableNumber', () {
      final order = Order(
        id: 'ORD-TEST-2',
        customerName: 'Original Name',
        fulfillment: 'dine-in',
        tableNumber: 'Table 8',
        items: const [],
        total: 500.0,
        status: 'pending',
        placedAt: DateTime(2026, 9, 18, 10, 0),
      );

      final acceptedOrder = order.copyWith(status: 'accepted');
      expect(acceptedOrder.status, 'accepted');
      expect(acceptedOrder.tableNumber, 'Table 8');

      final clearedTableOrder = order.copyWith(clearTableNumber: true);
      expect(clearedTableOrder.tableNumber, isNull);
    });

    test('Order fromJson and toJson match backend response contract', () {
      final json = {
        'id': '6aaa6bf28edf20dc38e937ac',
        '_id': '6aaa6bf28edf20dc38e937ac',
        'customerId': '6aaa6be88edf20dc38e937aa',
        'customerName': 'Smrutiprakash Rout',
        'fulfillment': 'dine-in',
        'tableNumber': '14',
        'items': [
          {
            '_id': 'it-1',
            'menuItemId': '6aaa25625a5c1215a384ba19',
            'name': 'Chicken Burger',
            'price': 79.0,
            'quantity': 1,
          }
        ],
        'itemTotal': 79.0,
        'total': 79.0,
        'status': 'accepted',
        'placedAt': '2026-10-04T10:00:00.000Z',
      };

      final order = Order.fromJson(json);

      expect(order.id, '6aaa6bf28edf20dc38e937ac');
      expect(order.customerName, 'Smrutiprakash Rout');
      expect(order.customerId, '6aaa6be88edf20dc38e937aa');
      expect(order.fulfillment, 'dine-in');
      expect(order.tableNumber, '14');
      expect(order.items.length, 1);
      expect(order.items.first.name, 'Chicken Burger');
      expect(order.items.first.price, 79.0);
      expect(order.items.first.quantity, 1);
      expect(order.total, 79.0);
      expect(order.status, 'accepted');
      expect(order.placedAt.year, 2026);

      final serialized = order.toJson();
      expect(serialized['id'], '6aaa6bf28edf20dc38e937ac');
      expect(serialized['customerName'], 'Smrutiprakash Rout');
      expect(serialized['fulfillment'], 'dine-in');
      expect(serialized['tableNumber'], '14');
      expect(serialized['status'], 'accepted');
    });

    test('Order fromJson gracefully handles omitted tableNumber', () {
      final json = {
        'id': 'ORD-NO-TABLE',
        'customerName': 'Walk-in Dine-in',
        'fulfillment': 'dine-in',
        'items': <Map<String, dynamic>>[],
        'total': 0.0,
        'status': 'pending',
        'placedAt': '2026-10-04T12:00:00.000Z',
      };

      final order = Order.fromJson(json);
      expect(order.isDineIn, isTrue);
      expect(order.tableNumber, isNull);
    });

    test('OrderStatusSegment enum correctly reflects values and labels', () {
      expect(OrderStatusSegment.pending.value, 'pending');
      expect(OrderStatusSegment.pending.label, 'Pending');

      expect(OrderStatusSegment.accepted.value, 'accepted');
      expect(OrderStatusSegment.accepted.label, 'Preparing'); // PRD §3.5 display label

      expect(OrderStatusSegment.completed.value, 'completed');
      expect(OrderStatusSegment.completed.label, 'Completed');
    });
  });

  group('Mock Orders Data (Task 4A-1 Requirements via Fixtures)', () {
    final fixedBase = DateTime(2026, 9, 18, 12, 0);
    final orders = createMockOrders(baseTime: fixedBase);

    test('Contains at least 2-3 orders in EACH status', () {
      final pending = orders.where((o) => o.status == 'pending').toList();
      final accepted = orders.where((o) => o.status == 'accepted').toList();
      final completed = orders.where((o) => o.status == 'completed').toList();
      final rejected = orders.where((o) => o.status == 'rejected').toList();

      expect(pending.length, greaterThanOrEqualTo(3));
      expect(accepted.length, greaterThanOrEqualTo(3));
      expect(completed.length, greaterThanOrEqualTo(3));
      expect(rejected.length, greaterThanOrEqualTo(3));
    });

    test('Contains a mix of fulfillment types across all orders', () {
      final dineInCount = orders.where((o) => o.isDineIn).length;
      final pickupCount = orders.where((o) => o.isPickup).length;

      expect(dineInCount, greaterThanOrEqualTo(4));
      expect(pickupCount, greaterThanOrEqualTo(4));
    });

    test('CRITICAL PRD A-25: Contains dine-in orders WITH and WITHOUT table numbers', () {
      final dineInWithTable = orders
          .where((o) => o.isDineIn && o.tableNumber != null && o.tableNumber!.isNotEmpty)
          .toList();
      final dineInWithoutTable = orders
          .where((o) => o.isDineIn && o.tableNumber == null)
          .toList();

      expect(dineInWithTable, isNotEmpty);
      expect(dineInWithoutTable, isNotEmpty);

      // Verify specific instance ORD-102 per specifications
      final ord102 = orders.firstWhere((o) => o.id == 'ORD-102');
      expect(ord102.isDineIn, isTrue);
      expect(ord102.tableNumber, isNull);

      // Verify pickup orders have null tableNumber
      final pickupOrders = orders.where((o) => o.isPickup);
      for (final p in pickupOrders) {
        expect(p.tableNumber, isNull);
      }
    });

    test('Includes varied item counts and totals', () {
      final itemCounts = orders.map((o) => o.items.length).toSet();
      expect(itemCounts.length, greaterThanOrEqualTo(3)); // Has 1, 2, 3, 4 items

      final totals = orders.map((o) => o.total).toSet();
      expect(totals.length, greaterThanOrEqualTo(5)); // Good variation of totals
    });

    test('placedAt timestamps are spread across recent times', () {
      for (final order in orders) {
        expect(order.placedAt.isBefore(fixedBase), isTrue);
      }

      // Check difference of earliest and latest
      final newest = orders.firstWhere((o) => o.id == 'ORD-101');
      final oldest = orders.firstWhere((o) => o.id == 'ORD-112');

      final diffNewest = fixedBase.difference(newest.placedAt);
      final diffOldest = fixedBase.difference(oldest.placedAt);

      expect(diffNewest.inMinutes, lessThanOrEqualTo(5));
      expect(diffOldest.inHours, greaterThanOrEqualTo(24));
    });

    test('getMockOrdersByStatus returns filtered subsets correctly', () {
      final pending = getMockOrdersByStatus('pending', baseTime: fixedBase);
      expect(pending.every((o) => o.status == 'pending'), isTrue);
      expect(pending.length, 3);
    });
  });
}
