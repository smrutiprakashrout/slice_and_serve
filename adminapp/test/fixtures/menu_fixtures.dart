import 'package:adminapp/core/result.dart';
import 'package:adminapp/models/category.dart';
import 'package:adminapp/models/menu_item.dart';
import 'package:adminapp/services/menu_service.dart';

/// Test fixture menu items for widget and integration tests.
const List<MenuItem> testMenuItems = [
  MenuItem(
    id: 'menu-1',
    name: 'Margherita Classic Pizza',
    subtitle:
        'San Marzano tomatoes, fresh mozzarella, basil & extra virgin olive oil',
    price: 249.0,
    categorySlug: 'pizza',
    type: 'veg',
    featured: true,
    image: null,
    available: true,
  ),
  MenuItem(
    id: 'menu-2',
    name: 'Double Cheese Burst Pizza',
    subtitle:
        'Molten cheese crust topped with herb-infused cheddar & mozzarella blend',
    price: 329.0,
    categorySlug: 'pizza',
    type: 'veg',
    featured: false,
    image: null,
    available: true,
  ),
  MenuItem(
    id: 'menu-3',
    name: 'Spicy Chicken Pepperoni Pizza',
    subtitle:
        'Smoked chicken pepperoni, chili flakes, roasted garlic & spicy red sauce',
    price: 389.0,
    categorySlug: 'pizza',
    type: 'non-veg',
    featured: true,
    image: null,
    available: true,
  ),
  MenuItem(
    id: 'menu-4',
    name: 'Smoked BBQ Chicken Pizza',
    subtitle:
        'Hickory BBQ sauce, diced chicken, caramelized onions & bell peppers',
    price: 419.0,
    categorySlug: 'pizza',
    type: 'non-veg',
    featured: false,
    image: null,
    available: false,
  ),
  MenuItem(
    id: 'menu-5',
    name: 'Crispy Paneer Burger',
    subtitle:
        'Panko crumbed spiced cottage cheese patty with mint mayo & fresh lettuce',
    price: 169.0,
    categorySlug: 'burger',
    type: 'veg',
    featured: false,
    image: null,
    available: true,
  ),
  MenuItem(
    id: 'menu-6',
    name: 'Classic Chicken Smash Burger',
    subtitle:
        'Double seared chicken patty, melted American cheddar & secret house relish',
    price: 219.0,
    categorySlug: 'burger',
    type: 'non-veg',
    featured: false,
    image: null,
    available: true,
  ),
  MenuItem(
    id: 'menu-7',
    name: 'Truffle Mushroom Burger',
    subtitle:
        'Sautéed wild mushrooms, swiss cheese, truffle aioli on brioche bun',
    price: 259.0,
    categorySlug: 'burger',
    type: 'veg',
    featured: false,
    image: null,
    available: false,
  ),
  MenuItem(
    id: 'menu-8',
    name: 'Loaded Garlic Breadsticks',
    subtitle:
        'Freshly baked pull-apart bread topped with garlic butter & melted herbs',
    price: 139.0,
    categorySlug: 'sides',
    type: 'veg',
    featured: false,
    image: null,
    available: true,
  ),
  MenuItem(
    id: 'menu-9',
    name: 'Peri Peri Crinkle Fries',
    subtitle: 'Golden crisp crinkle cut potatoes dusted in African bird’s eye chili',
    price: 119.0,
    categorySlug: 'sides',
    type: 'veg',
    featured: true,
    image: null,
    available: true,
  ),
  MenuItem(
    id: 'menu-10',
    name: 'Fresh Mint Lime Mojito',
    subtitle: 'Crushed spearmint, Persian lime juice, sparkling water & organic cane sugar',
    price: 99.0,
    categorySlug: 'drinks',
    type: 'veg',
    featured: false,
    image: null,
    available: true,
  ),
  MenuItem(
    id: 'menu-11',
    name: 'Warm Chocolate Lava Cake',
    subtitle: 'Gooey Belgian dark chocolate center dusted with confectioners sugar',
    price: 159.0,
    categorySlug: 'dessert',
    type: 'veg',
    featured: false,
    image: null,
    available: false,
  ),
  MenuItem(
    id: 'menu-12',
    name: 'Artisanal Tiramisu Cup',
    subtitle: 'Espresso-soaked savoiardi layered with whipped mascarpone cream',
    price: 189.0,
    categorySlug: 'dessert',
    type: 'veg',
    featured: false,
    image: null,
    available: false,
  ),
];

/// Test fixture categories for widget and integration tests.
const List<Category> testCategories = [
  Category(
    id: 'cat-1',
    name: 'Pizza',
    slug: 'pizza',
    icon: '🍕',
    sortOrder: 1,
  ),
  Category(
    id: 'cat-2',
    name: 'Burger',
    slug: 'burger',
    icon: '🍔',
    sortOrder: 2,
  ),
  Category(
    id: 'cat-3',
    name: 'Sides',
    slug: 'sides',
    icon: '🍟',
    sortOrder: 3,
  ),
  Category(
    id: 'cat-4',
    name: 'Drinks',
    slug: 'drinks',
    icon: '🥤',
    sortOrder: 4,
  ),
  Category(
    id: 'cat-5',
    name: 'Dessert',
    slug: 'dessert',
    icon: '🍰',
    sortOrder: 5,
  ),
];

/// Fake implementation of [MenuService] for widget testing.
class FakeMenuService implements MenuService {
  List<MenuItem> items;
  List<Category> categories;
  bool shouldFail;
  String errorMessage;
  bool shouldSetAvailabilityFail;
  String setAvailabilityErrorMessage;
  bool shouldCreateFail;
  String createErrorMessage;
  bool shouldUpdateFail;
  String updateErrorMessage;
  bool shouldDeleteFail;
  String deleteErrorMessage;
  bool shouldGetCategoriesFail;
  String getCategoriesErrorMessage;

  FakeMenuService({
    List<MenuItem>? initialItems,
    List<Category>? initialCategories,
    this.shouldFail = false,
    this.errorMessage = 'Network connection failed.',
    this.shouldSetAvailabilityFail = false,
    this.setAvailabilityErrorMessage = 'Failed to update availability.',
    this.shouldCreateFail = false,
    this.createErrorMessage = 'Validation failed on server.',
    this.shouldUpdateFail = false,
    this.updateErrorMessage = 'Validation failed on server.',
    this.shouldDeleteFail = false,
    this.deleteErrorMessage = 'Failed to delete menu item.',
    this.shouldGetCategoriesFail = false,
    this.getCategoriesErrorMessage = 'Failed to load categories.',
  })  : items = initialItems ?? List<MenuItem>.from(testMenuItems),
        categories = initialCategories ?? List<Category>.from(testCategories);

  @override
  Future<Result<List<MenuItem>>> getMenuItems() async {
    if (shouldFail) {
      return Result.failure(errorMessage);
    }
    return Result.success(List<MenuItem>.from(items));
  }

  @override
  Future<Result<MenuItem>> setAvailability(
    String itemId,
    bool available,
  ) async {
    if (shouldSetAvailabilityFail) {
      return Result.failure(setAvailabilityErrorMessage);
    }
    final index = items.indexWhere((i) => i.id == itemId);
    if (index == -1) {
      return const Result.failure('Menu item not found.');
    }
    final updated = items[index].copyWith(available: available);
    items[index] = updated;
    return Result.success(updated);
  }

  @override
  Future<Result<MenuItem>> patchAvailability(
    String itemId,
    bool available,
  ) =>
      setAvailability(itemId, available);

  @override
  Future<Result<MenuItem>> createMenuItem(MenuItem item) async {
    if (shouldCreateFail) {
      return Result.failure(
        createErrorMessage,
        statusCode: 400,
        errorCode: 'VALIDATION_ERROR',
      );
    }
    final newItem = item.id.isEmpty
        ? item.copyWith(id: 'created-${DateTime.now().millisecondsSinceEpoch}')
        : item;
    items.insert(0, newItem);
    return Result.success(newItem);
  }

  @override
  Future<Result<MenuItem>> updateMenuItem(String id, MenuItem item) async {
    if (shouldUpdateFail) {
      return Result.failure(
        updateErrorMessage,
        statusCode: 400,
        errorCode: 'VALIDATION_ERROR',
      );
    }
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      items[index] = item;
    } else {
      items.add(item);
    }
    return Result.success(item);
  }

  @override
  Future<Result<void>> deleteMenuItem(String id) async {
    if (shouldDeleteFail) {
      return Result.failure(
        deleteErrorMessage,
        statusCode: 500,
        errorCode: 'INTERNAL_ERROR',
      );
    }
    final index = items.indexWhere((i) => i.id == id);
    if (index != -1) {
      items.removeAt(index);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<List<Category>>> getCategories() async {
    if (shouldGetCategoriesFail) {
      return Result.failure(
        getCategoriesErrorMessage,
        statusCode: 500,
        errorCode: 'INTERNAL_ERROR',
      );
    }
    return Result.success(List<Category>.from(categories));
  }
}
