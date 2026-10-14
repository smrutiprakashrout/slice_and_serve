import 'package:flutter/foundation.dart';

/// Active status segment for filtering the orders list in the 3-segment reality.
///
/// Implements `PRD.md` §3.5 (A-24), `TASKS.md` 4A-5, and 4B-1:
/// - [pending]: "Pending" (raw value 'pending')
/// - [accepted]: "Preparing" (raw value 'accepted', display label 'Preparing')
/// - [completed]: "Completed" (raw value 'completed')
/// (Note: 'rejected' orders are never displayed in any segment per PRD §3.5)
enum OrderStatusSegment {
  pending('pending', 'Pending'),
  accepted('accepted', 'Preparing'),
  completed('completed', 'Completed');

  final String value;
  final String label;
  const OrderStatusSegment(this.value, this.label);
}

/// Immutable model representing an individual line item within an [Order].
///
/// Matches `ARCHITECTURE.md` §3 OrderItem specification:
/// - [name]: Item name (e.g. "Margherita Classic Pizza")
/// - [quantity]: Unit count ordered
/// - [price]: Price per unit in INR
@immutable
class OrderItem {
  final String name;
  final int quantity;
  final double price;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      menuItemId: json['menuItemId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      if (menuItemId != null) 'menuItemId': menuItemId,
    };
  }

  final String? menuItemId;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.menuItemId,
  });

  /// Total price for this line item (price * quantity).
  double get lineTotal => price * quantity;

  OrderItem copyWith({
    String? name,
    int? quantity,
    double? price,
    String? menuItemId,
  }) {
    return OrderItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      menuItemId: menuItemId ?? this.menuItemId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          quantity == other.quantity &&
          price == other.price &&
          menuItemId == other.menuItemId;

  @override
  int get hashCode => Object.hash(name, quantity, price, menuItemId);

  @override
  String toString() =>
      'OrderItem(name: $name, quantity: $quantity, price: $price, menuItemId: $menuItemId)';
}

/// Immutable model representing a customer order in Slice & Serve.
///
/// Matches `ARCHITECTURE.md` §3 and `PRD.md` §3.5 specifications:
/// - [id]: Unique order identifier (e.g. "ORD-101" or MongoDB ObjectID)
/// - [customerName]: Customer display name
/// - [fulfillment]: Fulfillment type ("dine-in" | "pickup")
/// - [tableNumber]: Table identifier for dine-in orders.
///   Nullable: per PRD A-25, dine-in orders can have no table number specified,
///   and its absence must render gracefully. Always null for pickup orders.
/// - [items]: List of ordered line items ([OrderItem])
/// - [total]: Order total in INR
/// - [status]: Order lifecycle state ("pending" | "accepted" | "completed" | "rejected")
/// - [placedAt]: Timestamp when order was placed
/// - [customerId]: Optional ID of customer who placed the order
/// - [itemTotal]: Optional subtotal of items
@immutable
class Order {
  final String id;
  final String customerName;
  final String fulfillment; // "dine-in" | "pickup"
  final String? tableNumber; // Nullable; optional for dine-in, null for pickup
  final List<OrderItem> items;
  final double total;
  final String status; // "pending" | "accepted" | "completed" | "rejected"
  final DateTime placedAt;
  final String? customerId;
  final double? itemTotal;

  const Order({
    required this.id,
    required this.customerName,
    required this.fulfillment,
    this.tableNumber,
    required this.items,
    required this.total,
    required this.status,
    required this.placedAt,
    this.customerId,
    this.itemTotal,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawPlacedAt = json['placedAt'] ?? json['createdAt'];
    final DateTime placedAt;
    if (rawPlacedAt is DateTime) {
      placedAt = rawPlacedAt;
    } else if (rawPlacedAt is String) {
      placedAt = DateTime.tryParse(rawPlacedAt) ?? DateTime.now();
    } else {
      placedAt = DateTime.now();
    }

    final rawItems = json['items'];
    final List<OrderItem> items;
    if (rawItems is List) {
      items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList();
    } else {
      items = const [];
    }

    final id = json['id'] as String? ?? json['_id'] as String? ?? '';
    final customerName = json['customerName'] as String? ?? '';
    final fulfillment = json['fulfillment'] as String? ?? 'dine-in';
    final tableNumber = json['tableNumber'] as String?;
    final total = (json['total'] as num?)?.toDouble() ??
        (json['itemTotal'] as num?)?.toDouble() ??
        0.0;
    final status = json['status'] as String? ?? 'pending';
    final customerId = json['customerId'] as String?;
    final itemTotal = (json['itemTotal'] as num?)?.toDouble();

    return Order(
      id: id,
      customerName: customerName,
      fulfillment: fulfillment,
      tableNumber: tableNumber,
      items: items,
      total: total,
      status: status,
      placedAt: placedAt,
      customerId: customerId,
      itemTotal: itemTotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'fulfillment': fulfillment,
      if (tableNumber != null) 'tableNumber': tableNumber,
      'items': items.map((i) => i.toJson()).toList(),
      'total': total,
      'status': status,
      'placedAt': placedAt.toIso8601String(),
      if (customerId != null) 'customerId': customerId,
      if (itemTotal != null) 'itemTotal': itemTotal,
    };
  }

  /// Fulfillment convenience helpers
  bool get isDineIn => fulfillment == 'dine-in';
  bool get isPickup => fulfillment == 'pickup';

  /// Lifecycle status convenience helpers
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';

  /// Total units count across all items in the order
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? id,
    String? customerName,
    String? fulfillment,
    String? tableNumber,
    bool clearTableNumber = false,
    List<OrderItem>? items,
    double? total,
    String? status,
    DateTime? placedAt,
    String? customerId,
    double? itemTotal,
  }) {
    return Order(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      fulfillment: fulfillment ?? this.fulfillment,
      tableNumber:
          clearTableNumber ? null : (tableNumber ?? this.tableNumber),
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      placedAt: placedAt ?? this.placedAt,
      customerId: customerId ?? this.customerId,
      itemTotal: itemTotal ?? this.itemTotal,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Order(id: $id, customer: $customerName, fulfillment: $fulfillment, table: $tableNumber, status: $status, total: $total)';
}
