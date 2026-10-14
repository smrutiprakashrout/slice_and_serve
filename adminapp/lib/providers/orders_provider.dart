import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/result.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';

/// Provider for [OrderService], injected with the shared [ApiClient].
final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderService(apiClient: apiClient);
});

/// Riverpod AsyncNotifier managing orders list state.
///
/// Implements `ARCHITECTURE.md` §3, §4, §7, `PRD.md` §3.5 (A-24, A-29),
/// `CODING_STANDARDS.md` §2, and `TASKS.md` Phase 4B (4B-1):
/// - Exposes `AsyncValue<List<Order>>` for the currently active segment
/// - Queries the API by the real status value ('pending', 'accepted', 'completed')
/// - Defensively enforces that rejected orders NEVER appear in any segment
/// - Supports [fetchSegment] for switching segments with loading transitions
/// - Supports [refresh] for pull-to-refresh
/// - Supports [updateOrderStatusLocally] for pre-4B-2 local action button mutations
/// - Caches counts across segments for the segmented control badges
class OrdersNotifier extends AsyncNotifier<List<Order>> {
  OrderStatusSegment _currentSegment = OrderStatusSegment.pending;
  final Map<OrderStatusSegment, List<Order>> _segmentCache = {};
  final Map<String, String> _localStatusOverrides = {};
  final Map<String, Order> _knownOrders = {};

  OrderStatusSegment get currentSegment => _currentSegment;

  @override
  FutureOr<List<Order>> build() async {
    return _fetchOrdersForSegment(_currentSegment);
  }

  /// Internal fetcher for a given segment using real API status values.
  Future<List<Order>> _fetchOrdersForSegment(OrderStatusSegment segment) async {
    final orderService = ref.watch(orderServiceProvider);
    final result = await orderService.getOrders(status: segment.value);

    return result.when(
      success: (orders) {
        // Track known orders in cache
        for (final o in orders) {
          _knownOrders[o.id] = o;
        }

        // Apply local status overrides and filter out rejected orders
        final filtered = <Order>[];
        for (final o in orders) {
          final effectiveStatus = _localStatusOverrides[o.id] ?? o.status;
          if (effectiveStatus == segment.value && effectiveStatus != 'rejected') {
            filtered.add(o.copyWith(status: effectiveStatus));
          }
        }

        // Check if any known order was locally moved into this segment
        for (final entry in _localStatusOverrides.entries) {
          if (entry.value == segment.value && segment.value != 'rejected') {
            if (!filtered.any((o) => o.id == entry.key)) {
              final known = _knownOrders[entry.key];
              if (known != null) {
                filtered.add(known.copyWith(status: segment.value));
              }
            }
          }
        }

        // Sort newest first by placedAt
        filtered.sort((a, b) => b.placedAt.compareTo(a.placedAt));
        _segmentCache[segment] = filtered;
        return filtered;
      },
      failure: (message, statusCode, errorCode) => throw Exception(message),
    );
  }

  /// Changes the active segment and fetches orders from the backend for that segment.
  Future<void> fetchSegment(OrderStatusSegment segment) async {
    if (_currentSegment == segment && state.hasValue) return;
    _currentSegment = segment;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchOrdersForSegment(segment));
  }

  /// Pull-to-refresh: re-fetches orders from the backend for the current segment.
  Future<void> refresh() async {
    final orderService = ref.read(orderServiceProvider);
    final result = await orderService.getOrders(status: _currentSegment.value);

    result.when(
      success: (orders) {
        for (final o in orders) {
          _knownOrders[o.id] = o;
        }

        final filtered = <Order>[];
        for (final o in orders) {
          final effectiveStatus = _localStatusOverrides[o.id] ?? o.status;
          if (effectiveStatus == _currentSegment.value && effectiveStatus != 'rejected') {
            filtered.add(o.copyWith(status: effectiveStatus));
          }
        }

        for (final entry in _localStatusOverrides.entries) {
          if (entry.value == _currentSegment.value && _currentSegment.value != 'rejected') {
            if (!filtered.any((o) => o.id == entry.key)) {
              final known = _knownOrders[entry.key];
              if (known != null) {
                filtered.add(known.copyWith(status: _currentSegment.value));
              }
            }
          }
        }

        filtered.sort((a, b) => b.placedAt.compareTo(a.placedAt));
        _segmentCache[_currentSegment] = filtered;
        state = AsyncValue.data(filtered);
      },
      failure: (message, statusCode, errorCode) {
        state = AsyncValue.error(Exception(message), StackTrace.current);
      },
    );
  }

  /// Accepts a pending order via [OrderService.acceptOrder].
  ///
  /// On success:
  /// - Transitions order to 'accepted'
  /// - Removes order from Pending segment immediately
  /// - Adds order to Accepted segment cache
  /// - Returns [Result.success] with updated [Order]
  ///
  /// On 409 Conflict:
  /// - Per PRD A-29 [B], triggers [refresh] to bring current segment in sync with server reality
  /// - Returns [Result.failure]
  Future<Result<Order>> acceptOrder(String orderId) async {
    final orderService = ref.read(orderServiceProvider);
    final result = await orderService.acceptOrder(orderId);

    return result.when(
      success: (updatedOrder) {
        _applyStatusTransitionLocally(updatedOrder, 'accepted');
        return Result.success(updatedOrder);
      },
      failure: (message, statusCode, errorCode) async {
        if (statusCode == 409) {
          await refresh();
        }
        return Result.failure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      },
    );
  }

  /// Rejects a pending order via [OrderService.rejectOrder].
  ///
  /// On success:
  /// - Transitions order to 'rejected'
  /// - Removes order from all visible segments (PRD A-27 / 4A-5)
  /// - Returns [Result.success] with updated [Order]
  ///
  /// On 409 Conflict:
  /// - Triggers [refresh] to sync list
  /// - Returns [Result.failure]
  Future<Result<Order>> rejectOrder(String orderId) async {
    final orderService = ref.read(orderServiceProvider);
    final result = await orderService.rejectOrder(orderId);

    return result.when(
      success: (updatedOrder) {
        _applyStatusTransitionLocally(updatedOrder, 'rejected');
        return Result.success(updatedOrder);
      },
      failure: (message, statusCode, errorCode) async {
        if (statusCode == 409) {
          await refresh();
        }
        return Result.failure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      },
    );
  }

  /// Completes an accepted order via [OrderService.completeOrder].
  ///
  /// On success:
  /// - Transitions order to 'completed'
  /// - Removes order from Preparing segment immediately
  /// - Adds order to Completed segment cache
  /// - Returns [Result.success] with updated [Order]
  ///
  /// On 409 Conflict:
  /// - Triggers [refresh] to sync list
  /// - Returns [Result.failure]
  Future<Result<Order>> completeOrder(String orderId) async {
    final orderService = ref.read(orderServiceProvider);
    final result = await orderService.completeOrder(orderId);

    return result.when(
      success: (updatedOrder) {
        _applyStatusTransitionLocally(updatedOrder, 'completed');
        return Result.success(updatedOrder);
      },
      failure: (message, statusCode, errorCode) async {
        if (statusCode == 409) {
          await refresh();
        }
        return Result.failure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      },
    );
  }

  /// Internal helper to update memory state across all segments following a transition.
  void _applyStatusTransitionLocally(Order updatedOrder, String newStatus) {
    _knownOrders[updatedOrder.id] = updatedOrder;

    // Update active segment list
    final currentList = state.value;
    if (currentList != null) {
      final updatedList = List<Order>.from(currentList);
      final idx = updatedList.indexWhere((o) => o.id == updatedOrder.id);
      if (idx != -1) {
        if (newStatus == _currentSegment.value && newStatus != 'rejected') {
          updatedList[idx] = updatedOrder;
        } else {
          updatedList.removeAt(idx);
        }
        state = AsyncValue.data(updatedList);
      }
    }

    // Update caches for all segments
    for (final seg in OrderStatusSegment.values) {
      if (_segmentCache.containsKey(seg)) {
        final list = List<Order>.from(_segmentCache[seg]!);
        list.removeWhere((o) => o.id == updatedOrder.id);
        if (newStatus == seg.value && newStatus != 'rejected') {
          list.insert(0, updatedOrder);
          list.sort((a, b) => b.placedAt.compareTo(a.placedAt));
        }
        _segmentCache[seg] = list;
      }
    }
  }

  /// Mutates order status locally in memory.
  ///
  /// Kept for test harness support and local overrides.
  void updateOrderStatusLocally(Order order, String newStatus) {
    _localStatusOverrides[order.id] = newStatus;
    _applyStatusTransitionLocally(order.copyWith(status: newStatus), newStatus);
  }

  /// Cached count of orders for a given segment.
  int countForSegment(OrderStatusSegment segment) {
    return _segmentCache[segment]?.length ?? 0;
  }

  /// Current count of orders in "pending" status.
  ///
  /// Uses active list length when currently on [OrderStatusSegment.pending] and loaded,
  /// otherwise uses the cached pending segment count.
  int get pendingCount {
    if (_currentSegment == OrderStatusSegment.pending && state.hasValue) {
      return state.value?.length ?? 0;
    }
    return _segmentCache[OrderStatusSegment.pending]?.length ?? 0;
  }

  /// Refreshes orders and updates pending count cache on tab visit per PRD A-7 / A-28.
  Future<void> refreshOnTabVisit() async {
    await refresh();
    if (_currentSegment != OrderStatusSegment.pending) {
      await _fetchPendingCountSilently();
    }
  }

  /// Silently fetches the pending orders list in the background to keep the badge count fresh
  /// even when the user is viewing a different segment.
  Future<void> _fetchPendingCountSilently() async {
    try {
      final orderService = ref.read(orderServiceProvider);
      final result = await orderService.getOrders(status: 'pending');
      result.when(
        success: (orders) {
          for (final o in orders) {
            _knownOrders[o.id] = o;
          }
          final filtered = <Order>[];
          for (final o in orders) {
            final effectiveStatus = _localStatusOverrides[o.id] ?? o.status;
            if (effectiveStatus == 'pending' && effectiveStatus != 'rejected') {
              filtered.add(o.copyWith(status: effectiveStatus));
            }
          }
          filtered.sort((a, b) => b.placedAt.compareTo(a.placedAt));
          _segmentCache[OrderStatusSegment.pending] = filtered;
          if (state.hasValue) {
            state = AsyncValue.data(state.value!);
          }
        },
        failure: (_, _, _) {},
      );
    } catch (_) {}
  }

  /// Sets initial orders for testing harnesses.
  void setInitialOrders(List<Order> orders) {
    for (final o in orders) {
      _knownOrders[o.id] = o;
    }

    for (final segment in OrderStatusSegment.values) {
      _segmentCache[segment] = orders
          .where((o) => o.status == segment.value && o.status != 'rejected')
          .toList()
        ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
    }

    state = AsyncValue.data(_segmentCache[_currentSegment] ?? []);
  }
}

/// Main orders provider exposing `AsyncValue<List<Order>>`.
final ordersProvider = AsyncNotifierProvider<OrdersNotifier, List<Order>>(
  OrdersNotifier.new,
);

/// Provider exposing the real count of orders currently in "pending" status.
///
/// Implements `PRD.md` §3.2 (A-7), §3.5 (A-28), and `TASKS.md` Phase 4B (4B-3):
/// - Derived from [ordersProvider] state when on pending segment or cached pending list
/// - Automatically updates when actions (accept/reject) alter pending orders
/// - Refreshed at minimum on each visit to the Orders tab
final pendingOrdersCountProvider = Provider<int>((ref) {
  final ordersState = ref.watch(ordersProvider);
  final notifier = ref.watch(ordersProvider.notifier);

  if (notifier.currentSegment == OrderStatusSegment.pending && ordersState.hasValue) {
    return ordersState.value?.length ?? 0;
  }
  return notifier.countForSegment(OrderStatusSegment.pending);
});
