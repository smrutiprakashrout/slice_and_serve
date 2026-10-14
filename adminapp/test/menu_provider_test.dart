import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/core/result.dart';
import 'package:adminapp/models/menu_item.dart';
import 'package:adminapp/providers/menu_provider.dart';
import 'fixtures/menu_fixtures.dart';

void main() {
  group('MenuNotifier / menuProvider Tests (Task 2B-1)', () {
    test('initial build loads items from MenuService successfully', () async {
      final fakeService = FakeMenuService();
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final items = await container.read(menuProvider.future);

      expect(items.length, testMenuItems.length);
      expect(items.first.id, testMenuItems.first.id);
      expect(items.first.name, testMenuItems.first.name);
    });

    test('refresh reloads items and reflects service updates', () async {
      final fakeService = FakeMenuService();
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(menuProvider.future);

      // Modify fake service data
      fakeService.items.insert(
        0,
        const MenuItem(
          id: 'new-live-item',
          name: 'Newly Added Item',
          subtitle: 'Fresh off the oven',
          price: 99.0,
          categorySlug: 'pizza',
          type: 'veg',
        ),
      );

      await container.read(menuProvider.notifier).refresh();

      final updated = container.read(menuProvider).value;
      expect(updated, isNotNull);
      expect(updated!.first.id, 'new-live-item');
      expect(updated.first.name, 'Newly Added Item');
    });

    test('toggleAvailability updates item availability optimistically in memory',
        () async {
      final fakeService = FakeMenuService();
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final initialItems = await container.read(menuProvider.future);
      final firstItem = initialItems.first;
      expect(firstItem.available, isTrue);

      await container
          .read(menuProvider.notifier)
          .toggleAvailability(firstItem.id, false);

      final updatedItems = container.read(menuProvider).value;
      expect(updatedItems, isNotNull);
      expect(
        updatedItems!.firstWhere((i) => i.id == firstItem.id).available,
        isFalse,
      );

      await container
          .read(menuProvider.notifier)
          .toggleAvailability(firstItem.id, true);

      final toggledBack = container.read(menuProvider).value;
      expect(
        toggledBack!.firstWhere((i) => i.id == firstItem.id).available,
        isTrue,
      );
    });

    test(
        'toggleAvailability reverts optimistic update back to prior value on failure',
        () async {
      final fakeService = FakeMenuService(
        shouldSetAvailabilityFail: true,
        setAvailabilityErrorMessage: 'Network failure',
      );
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final initialItems = await container.read(menuProvider.future);
      final firstItem = initialItems.first;
      expect(firstItem.available, isTrue);

      final result = await container
          .read(menuProvider.notifier)
          .toggleAvailability(firstItem.id, false);

      expect(result.isFailure, isTrue);

      // Verify the in-memory state reverted back to original available: true
      final currentItems = container.read(menuProvider).value;
      expect(currentItems, isNotNull);
      expect(
        currentItems!.firstWhere((i) => i.id == firstItem.id).available,
        isTrue,
      );
    });

    test('addItem, updateItem, and removeItem manage local state correctly',
        () async {
      final fakeService = FakeMenuService();
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(menuProvider.future);

      const newItem = MenuItem(
        id: 'brand-new-item',
        name: 'Brand New Item',
        subtitle: 'New item subtitle',
        price: 150.0,
        categorySlug: 'burger',
        type: 'non-veg',
      );

      // Add item
      container.read(menuProvider.notifier).addItem(newItem);
      var current = container.read(menuProvider).value!;
      expect(current.first.id, 'brand-new-item');

      // Update item
      final updatedItem = newItem.copyWith(name: 'Updated Name');
      container.read(menuProvider.notifier).updateItem(updatedItem);
      current = container.read(menuProvider).value!;
      expect(current.firstWhere((i) => i.id == 'brand-new-item').name,
          'Updated Name');

      // Remove item
      container.read(menuProvider.notifier).removeItem('brand-new-item');
      current = container.read(menuProvider).value!;
      expect(
        current.any((i) => i.id == 'brand-new-item'),
        isFalse,
      );
    });

    test('initial build sets AsyncError when MenuService returns failure',
        () async {
      final fakeService = FakeMenuService(
        shouldFail: true,
        errorMessage: 'Unable to reach backend',
      );
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      container.read(menuProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(menuProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Unable to reach backend'));
    });

    test('createMenuItem adds created item to state on service success',
        () async {
      final fakeService = FakeMenuService();
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(menuProvider.future);

      const newItem = MenuItem(
        id: '',
        name: 'Crispy Onion Rings',
        subtitle: 'Battered sweet onions',
        price: 129.0,
        categorySlug: 'sides',
        type: 'veg',
      );

      final result =
          await container.read(menuProvider.notifier).createMenuItem(newItem);
      expect(result.isSuccess, isTrue);

      final current = container.read(menuProvider).value!;
      expect(current.first.name, 'Crispy Onion Rings');
      expect(current.first.price, 129.0);
    });

    test('createMenuItem returns failure and preserves state on error',
        () async {
      final fakeService = FakeMenuService(
        shouldCreateFail: true,
        createErrorMessage: 'Server rejected item',
      );
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(menuProvider.future);
      final initialCount = initial.length;

      const newItem = MenuItem(
        id: '',
        name: 'Failed Item',
        subtitle: 'Will fail',
        price: 99.0,
        categorySlug: 'burger',
        type: 'veg',
      );

      final result =
          await container.read(menuProvider.notifier).createMenuItem(newItem);
      expect(result.isFailure, isTrue);

      final current = container.read(menuProvider).value!;
      expect(current.length, initialCount);
      expect(current.any((i) => i.name == 'Failed Item'), isFalse);
    });

    test('updateMenuItem replaces item in state on service success',
        () async {
      final fakeService = FakeMenuService();
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(menuProvider.future);
      final target = initial.first;

      final updated = target.copyWith(price: 499.0, name: 'Premium ${target.name}');
      final result = await container
          .read(menuProvider.notifier)
          .updateMenuItem(target.id, updated);
      expect(result.isSuccess, isTrue);

      final current = container.read(menuProvider).value!;
      final found = current.firstWhere((i) => i.id == target.id);
      expect(found.price, 499.0);
      expect(found.name, contains('Premium'));
    });

    test('deleteMenuItem removes item from state on service success',
        () async {
      final fakeService = FakeMenuService();
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(menuProvider.future);
      final target = initial.first;

      final result = await container
          .read(menuProvider.notifier)
          .deleteMenuItem(target.id);
      expect(result.isSuccess, isTrue);

      final current = container.read(menuProvider).value!;
      expect(current.any((i) => i.id == target.id), isFalse);
      expect(current.length, initial.length - 1);
    });

    test('deleteMenuItem preserves item in state on service failure',
        () async {
      final fakeService = FakeMenuService(
        shouldDeleteFail: true,
        deleteErrorMessage: 'Server error deleting item.',
      );
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(menuProvider.future);
      final target = initial.first;

      final result = await container
          .read(menuProvider.notifier)
          .deleteMenuItem(target.id);
      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.errorMessage, 'Server error deleting item.');

      final current = container.read(menuProvider).value!;
      expect(current.any((i) => i.id == target.id), isTrue);
      expect(current.length, initial.length);
    });
  });

  group('categoriesProvider Tests (Task 2B-5)', () {
    test('loads categories from MenuService successfully', () async {
      final fakeService = FakeMenuService();
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      final categories = await container.read(categoriesProvider.future);

      expect(categories.length, testCategories.length);
      expect(categories[0].name, 'Pizza');
      expect(categories[0].slug, 'pizza');
      expect(categories[1].name, 'Burger');
      expect(categories[1].slug, 'burger');
    });

    test('categoriesProvider sets error when service fails', () async {
      final fakeService = FakeMenuService(
        shouldGetCategoriesFail: true,
        getCategoriesErrorMessage: 'Network failure fetching categories.',
      );
      final container = ProviderContainer(
        overrides: [
          menuServiceProvider.overrideWithValue(fakeService),
        ],
      );
      addTearDown(container.dispose);

      container.read(categoriesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(categoriesProvider);
      expect(state.hasError, isTrue);
      expect(
        state.error.toString(),
        contains('Network failure fetching categories.'),
      );
    });
  });
}
