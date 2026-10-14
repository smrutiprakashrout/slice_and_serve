import 'package:adminapp/core/result.dart';
import 'package:adminapp/models/order.dart';
import 'package:adminapp/services/order_service.dart';

/// Test fixture orders for widget and integration tests.
List<Order> createMockOrders({DateTime? baseTime}) {
  final now = baseTime ?? DateTime.now();

  return [
    // -------------------------------------------------------------------------
    // PENDING ORDERS (Newest first)
    // -------------------------------------------------------------------------
    Order(
      id: 'ORD-101',
      customerName: 'Aarav Mehta',
      fulfillment: 'dine-in',
      tableNumber: 'Table 4', // Dine-in WITH table number
      items: const [
        OrderItem(
          name: 'Margherita Classic Pizza',
          quantity: 2,
          price: 249.0,
        ),
      ],
      total: 498.0,
      status: 'pending',
      placedAt: now.subtract(const Duration(minutes: 2)), // 2 min ago
    ),
    Order(
      id: 'ORD-102',
      customerName: 'Priya Sundaram',
      fulfillment: 'dine-in',
      tableNumber: null, // CRITICAL (PRD A-25): Dine-in with NO table number
      items: const [
        OrderItem(
          name: 'Double Cheese Burst Pizza',
          quantity: 1,
          price: 329.0,
        ),
        OrderItem(
          name: 'Truffle Herb Potato Fries',
          quantity: 1,
          price: 149.0,
        ),
        OrderItem(
          name: 'Mango Passion Iced Cooler',
          quantity: 2,
          price: 129.0,
        ),
      ],
      total: 736.0,
      status: 'pending',
      placedAt: now.subtract(const Duration(minutes: 7)), // 7 min ago
    ),
    Order(
      id: 'ORD-103',
      customerName: 'Vikram Malhotra',
      fulfillment: 'pickup',
      tableNumber: null, // Pickup orders never have table numbers
      items: const [
        OrderItem(
          name: 'Spicy Chicken Pepperoni Pizza',
          quantity: 2,
          price: 389.0,
        ),
        OrderItem(
          name: 'Classic Chicken Smash Burger',
          quantity: 1,
          price: 229.0,
        ),
        OrderItem(
          name: 'Truffle Herb Potato Fries',
          quantity: 1,
          price: 149.0,
        ),
        OrderItem(
          name: 'Warm Belgian Chocolate Lava Cake',
          quantity: 1,
          price: 179.0,
        ),
      ],
      total: 1335.0,
      status: 'pending',
      placedAt: now.subtract(const Duration(minutes: 18)), // 18 min ago
    ),

    // -------------------------------------------------------------------------
    // ACCEPTED ORDERS (In kitchen preparation)
    // -------------------------------------------------------------------------
    Order(
      id: 'ORD-104',
      customerName: 'Riya Sharma',
      fulfillment: 'pickup',
      tableNumber: null,
      items: const [
        OrderItem(
          name: 'Crispy Paneer Burger',
          quantity: 1,
          price: 189.0,
        ),
      ],
      total: 189.0,
      status: 'accepted',
      placedAt: now.subtract(const Duration(minutes: 35)), // 35 min ago
    ),
    Order(
      id: 'ORD-105',
      customerName: 'Rohan Deshmukh',
      fulfillment: 'dine-in',
      tableNumber: 'Table 12', // Dine-in WITH table number
      items: const [
        OrderItem(
          name: 'Margherita Classic Pizza',
          quantity: 1,
          price: 249.0,
        ),
        OrderItem(
          name: 'Warm Belgian Chocolate Lava Cake',
          quantity: 1,
          price: 179.0,
        ),
      ],
      total: 428.0,
      status: 'accepted',
      placedAt: now.subtract(const Duration(minutes: 52)), // 52 min ago
    ),
    Order(
      id: 'ORD-106',
      customerName: 'Meera Nambiar',
      fulfillment: 'dine-in',
      tableNumber: null, // Dine-in with NO table number
      items: const [
        OrderItem(
          name: 'Smoked BBQ Chicken Pizza',
          quantity: 1,
          price: 419.0,
        ),
        OrderItem(
          name: 'Classic Chicken Smash Burger',
          quantity: 2,
          price: 229.0,
        ),
        OrderItem(
          name: 'Mango Passion Iced Cooler',
          quantity: 2,
          price: 129.0,
        ),
      ],
      total: 1135.0,
      status: 'accepted',
      placedAt: now.subtract(const Duration(hours: 1, minutes: 15)), // ~1h ago
    ),

    // -------------------------------------------------------------------------
    // COMPLETED ORDERS (Fulfilled & closed)
    // -------------------------------------------------------------------------
    Order(
      id: 'ORD-107',
      customerName: 'Kabir Verma',
      fulfillment: 'dine-in',
      tableNumber: 'Table 2', // Dine-in WITH table number
      items: const [
        OrderItem(
          name: 'Double Cheese Burst Pizza',
          quantity: 1,
          price: 329.0,
        ),
      ],
      total: 329.0,
      status: 'completed',
      placedAt: now.subtract(const Duration(hours: 2, minutes: 40)), // ~2.5h ago
    ),
    Order(
      id: 'ORD-108',
      customerName: 'Ananya Patel',
      fulfillment: 'pickup',
      tableNumber: null,
      items: const [
        OrderItem(
          name: 'Spicy Chicken Pepperoni Pizza',
          quantity: 1,
          price: 389.0,
        ),
        OrderItem(
          name: 'Truffle Herb Potato Fries',
          quantity: 1,
          price: 149.0,
        ),
        OrderItem(
          name: 'Mango Passion Iced Cooler',
          quantity: 1,
          price: 129.0,
        ),
      ],
      total: 667.0,
      status: 'completed',
      placedAt: now.subtract(const Duration(hours: 4, minutes: 10)), // ~4h ago
    ),
    Order(
      id: 'ORD-109',
      customerName: 'Karan Johar',
      fulfillment: 'dine-in',
      tableNumber: 'Table 7', // Dine-in WITH table number
      items: const [
        OrderItem(
          name: 'Crispy Paneer Burger',
          quantity: 2,
          price: 189.0,
        ),
        OrderItem(
          name: 'Truffle Herb Potato Fries',
          quantity: 2,
          price: 149.0,
        ),
      ],
      total: 676.0,
      status: 'completed',
      placedAt: now.subtract(const Duration(hours: 6)), // 6h ago
    ),

    // -------------------------------------------------------------------------
    // REJECTED ORDERS (Cancelled / declined)
    // -------------------------------------------------------------------------
    Order(
      id: 'ORD-110',
      customerName: 'Neha Gupta',
      fulfillment: 'pickup',
      tableNumber: null,
      items: const [
        OrderItem(
          name: 'Margherita Classic Pizza',
          quantity: 1,
          price: 249.0,
        ),
      ],
      total: 249.0,
      status: 'rejected',
      placedAt: now.subtract(const Duration(hours: 1, minutes: 5)), // ~1h ago
    ),
    Order(
      id: 'ORD-111',
      customerName: 'Devansh Joshi',
      fulfillment: 'dine-in',
      tableNumber: 'Table 9', // Dine-in WITH table number
      items: const [
        OrderItem(
          name: 'Smoked BBQ Chicken Pizza',
          quantity: 1,
          price: 419.0,
        ),
        OrderItem(
          name: 'Warm Belgian Chocolate Lava Cake',
          quantity: 1,
          price: 179.0,
        ),
      ],
      total: 598.0,
      status: 'rejected',
      placedAt: now.subtract(const Duration(hours: 3, minutes: 20)), // ~3h ago
    ),
    Order(
      id: 'ORD-112',
      customerName: 'Sunita Rao',
      fulfillment: 'dine-in',
      tableNumber: null, // Dine-in with NO table number
      items: const [
        OrderItem(
          name: 'Double Cheese Burst Pizza',
          quantity: 2,
          price: 329.0,
        ),
        OrderItem(
          name: 'Classic Chicken Smash Burger',
          quantity: 1,
          price: 229.0,
        ),
        OrderItem(
          name: 'Mango Passion Iced Cooler',
          quantity: 3,
          price: 129.0,
        ),
      ],
      total: 1274.0,
      status: 'rejected',
      placedAt: now.subtract(const Duration(days: 1, hours: 2)), // Yesterday
    ),
  ];
}

List<Order> get mockOrders => createMockOrders();

List<Order> getMockOrdersByStatus(String status, {DateTime? baseTime}) {
  return createMockOrders(baseTime: baseTime)
      .where((order) => order.status == status)
      .toList();
}

/// Fake implementation of [OrderService] for tests.
class FakeOrderService implements OrderService {
  final List<Order> orders;
  bool shouldGetOrdersFail = false;
  bool shouldAcceptFail = false;
  bool shouldRejectFail = false;
  bool shouldCompleteFail = false;
  bool return409OnAction = false;
  String action409Message = 'Cannot transition an order from pending to accepted.';
  String getOrdersErrorMessage = 'Failed to load orders from network';

  FakeOrderService({List<Order>? initialOrders})
      : orders = initialOrders != null
            ? List<Order>.from(initialOrders)
            : createMockOrders();

  @override
  Future<Result<List<Order>>> getOrders({
    String? status,
    int? limit,
    int? skip,
  }) async {
    if (shouldGetOrdersFail) {
      return Result.failure(
        getOrdersErrorMessage,
        statusCode: 500,
        errorCode: 'NETWORK_ERROR',
      );
    }

    var list = List<Order>.from(orders);
    if (status != null && status.isNotEmpty) {
      list = list.where((o) => o.status == status).toList();
    }
    list.sort((a, b) => b.placedAt.compareTo(a.placedAt));

    if (skip != null && skip > 0) {
      list = list.skip(skip).toList();
    }
    if (limit != null && limit > 0) {
      list = list.take(limit).toList();
    }

    return Result.success(list);
  }

  @override
  Future<Result<Order>> acceptOrder(String id) async {
    if (return409OnAction) {
      return Result.failure(
        action409Message,
        statusCode: 409,
        errorCode: 'INVALID_TRANSITION',
      );
    }
    if (shouldAcceptFail) {
      return const Result.failure('Failed to accept order', statusCode: 500);
    }
    final idx = orders.indexWhere((o) => o.id == id);
    if (idx == -1) {
      return const Result.failure('Order not found', statusCode: 404);
    }
    final updated = orders[idx].copyWith(status: 'accepted');
    orders[idx] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Order>> rejectOrder(String id) async {
    if (return409OnAction) {
      return Result.failure(
        action409Message,
        statusCode: 409,
        errorCode: 'INVALID_TRANSITION',
      );
    }
    if (shouldRejectFail) {
      return const Result.failure('Failed to reject order', statusCode: 500);
    }
    final idx = orders.indexWhere((o) => o.id == id);
    if (idx == -1) {
      return const Result.failure('Order not found', statusCode: 404);
    }
    final updated = orders[idx].copyWith(status: 'rejected');
    orders[idx] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<Order>> completeOrder(String id) async {
    if (return409OnAction) {
      return Result.failure(
        action409Message,
        statusCode: 409,
        errorCode: 'INVALID_TRANSITION',
      );
    }
    if (shouldCompleteFail) {
      return const Result.failure('Failed to complete order', statusCode: 500);
    }
    final idx = orders.indexWhere((o) => o.id == id);
    if (idx == -1) {
      return const Result.failure('Order not found', statusCode: 404);
    }
    final updated = orders[idx].copyWith(status: 'completed');
    orders[idx] = updated;
    return Result.success(updated);
  }
}

