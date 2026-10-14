import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/result.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../services/menu_service.dart';
import 'auth_provider.dart';

/// Provider for [MenuService], injected with the shared [ApiClient].
final menuServiceProvider = Provider<MenuService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MenuService(apiClient: apiClient);
});

/// Provider exposing the list of real categories fetched via [MenuService.getCategories].
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final menuService = ref.watch(menuServiceProvider);
  final result = await menuService.getCategories();
  return result.when(
    success: (categories) => categories,
    failure: (message, statusCode, errorCode) => throw Exception(message),
  );
});

/// Riverpod AsyncNotifier managing the menu items state.
///
/// Implements `ARCHITECTURE.md` §3, §4, §5.2, `CODING_STANDARDS.md` §2, and `TASKS.md` Phase 2B (2B-1, 2B-2).
/// - Initial state loaded via `MenuService.getMenuItems()`
/// - [refresh] reloads items without showing full-screen loading when data already exists
/// - [toggleAvailability] / [setAvailability] provides optimistic toggle with server PATCH and rollback on failure
/// - [addItem], [updateItem], [removeItem] provide local state updates for create/edit/delete
class MenuNotifier extends AsyncNotifier<List<MenuItem>> {
  @override
  FutureOr<List<MenuItem>> build() async {
    final menuService = ref.watch(menuServiceProvider);
    final result = await menuService.getMenuItems();
    return result.when(
      success: (items) => items,
      failure: (message, statusCode, errorCode) => throw Exception(message),
    );
  }

  /// Reloads menu items from the server without resetting existing data to loading state.
  Future<void> refresh() async {
    final menuService = ref.read(menuServiceProvider);
    final result = await menuService.getMenuItems();
    result.when(
      success: (items) {
        state = AsyncValue.data(items);
      },
      failure: (message, statusCode, errorCode) {
        state = AsyncValue.error(Exception(message), StackTrace.current);
      },
    );
  }

  /// Optimistically toggles or sets availability for item [id].
  ///
  /// 1. Immediately updates the in-memory item using [MenuItem.copyWith] so UI flips instantly.
  /// 2. Dispatches [MenuService.setAvailability] in the background.
  /// 3. On success, reconciles with the server-returned item.
  /// 4. On failure, reverts the optimistic change back to the previous state and returns [Result.failure].
  Future<Result<MenuItem>> toggleAvailability(
    String id, [
    bool? newStatus,
  ]) async {
    final currentList = state.value;
    if (currentList == null) {
      return const Result.failure('Menu items not loaded');
    }

    final targetIndex = currentList.indexWhere((item) => item.id == id);
    if (targetIndex == -1) {
      return const Result.failure('Menu item not found');
    }

    final originalItem = currentList[targetIndex];
    final targetStatus = newStatus ?? !originalItem.available;

    if (originalItem.available == targetStatus) {
      return Result.success(originalItem);
    }

    // 1. Immediately update local state optimistically
    final optimisticList = List<MenuItem>.from(currentList);
    optimisticList[targetIndex] = originalItem.copyWith(available: targetStatus);
    state = AsyncValue.data(optimisticList);

    // 2. Call menu_service.dart's setAvailability in background
    final menuService = ref.read(menuServiceProvider);
    final result = await menuService.setAvailability(id, targetStatus);

    return result.when(
      success: (serverItem) {
        // 3. Reconcile with server response if still in data state
        final latestList = state.value;
        if (latestList != null) {
          final idx = latestList.indexWhere((i) => i.id == id);
          if (idx != -1) {
            final reconciled = List<MenuItem>.from(latestList);
            reconciled[idx] = serverItem;
            state = AsyncValue.data(reconciled);
          }
        }
        return Result.success(serverItem);
      },
      failure: (message, statusCode, errorCode) {
        // 4. Revert optimistic change back to prior value
        final latestList = state.value;
        if (latestList != null) {
          final idx = latestList.indexWhere((i) => i.id == id);
          if (idx != -1) {
            final reverted = List<MenuItem>.from(latestList);
            reverted[idx] = originalItem;
            state = AsyncValue.data(reverted);
          }
        }
        return Result.failure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      },
    );
  }

  /// Sets availability for item [id] to [available]. Alias to [toggleAvailability].
  Future<Result<MenuItem>> setAvailability(String id, bool available) =>
      toggleAvailability(id, available);

  /// Creates a new menu item via [MenuService.createMenuItem].
  ///
  /// On success, prepends the new item to the in-memory list and returns [Result.success].
  /// On failure, preserves state and returns [Result.failure].
  Future<Result<MenuItem>> createMenuItem(MenuItem item) async {
    final menuService = ref.read(menuServiceProvider);
    final result = await menuService.createMenuItem(item);

    return result.when(
      success: (createdItem) {
        final currentList = state.value ?? <MenuItem>[];
        state = AsyncValue.data([createdItem, ...currentList]);
        return Result.success(createdItem);
      },
      failure: (message, statusCode, errorCode) {
        return Result.failure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      },
    );
  }

  /// Updates an existing menu item via [MenuService.updateMenuItem].
  ///
  /// On success, replaces the item in the in-memory list and returns [Result.success].
  /// On failure, preserves state and returns [Result.failure].
  Future<Result<MenuItem>> updateMenuItem(String id, MenuItem item) async {
    final menuService = ref.read(menuServiceProvider);
    final result = await menuService.updateMenuItem(id, item);

    return result.when(
      success: (updatedItem) {
        final currentList = state.value;
        if (currentList != null) {
          state = AsyncValue.data(
            currentList.map((i) => i.id == id ? updatedItem : i).toList(),
          );
        }
        return Result.success(updatedItem);
      },
      failure: (message, statusCode, errorCode) {
        return Result.failure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      },
    );
  }

  /// Deletes an existing menu item via [MenuService.deleteMenuItem].
  ///
  /// On success, removes the item from the in-memory list and returns [Result.success].
  /// On failure, preserves the list state and returns [Result.failure].
  Future<Result<void>> deleteMenuItem(String id) async {
    final menuService = ref.read(menuServiceProvider);
    final result = await menuService.deleteMenuItem(id);

    return result.when(
      success: (_) {
        removeItem(id);
        return const Result.success(null);
      },
      failure: (message, statusCode, errorCode) {
        return Result.failure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      },
    );
  }

  /// Alias to [deleteMenuItem].
  Future<Result<void>> deleteItem(String id) => deleteMenuItem(id);

  /// Inserts a newly created [item] at the top of the list in memory.
  void addItem(MenuItem item) {
    final currentList = state.value ?? <MenuItem>[];
    state = AsyncValue.data([item, ...currentList]);
  }

  /// Updates an existing [item] in memory.
  void updateItem(MenuItem item) {
    final currentList = state.value;
    if (currentList == null) return;
    state = AsyncValue.data(
      currentList.map((MenuItem i) => i.id == item.id ? item : i).toList(),
    );
  }

  /// Removes an item with [id] in memory.
  void removeItem(String id) {
    final currentList = state.value;
    if (currentList == null) return;
    state = AsyncValue.data(
      currentList.where((MenuItem i) => i.id != id).toList(),
    );
  }
}

/// The global provider for menu items.
final menuProvider =
    AsyncNotifierProvider<MenuNotifier, List<MenuItem>>(() {
  return MenuNotifier();
});
