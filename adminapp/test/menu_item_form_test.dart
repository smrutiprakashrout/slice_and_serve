import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/models/menu_item.dart';
import 'package:adminapp/providers/menu_provider.dart';
import 'package:adminapp/screens/menu/menu_item_form.dart';
import 'package:adminapp/theme/app_theme.dart';
import 'fixtures/menu_fixtures.dart';

void main() {
  Widget buildTestForm({
    MenuItem? item,
    ValueChanged<MenuItem>? onSave,
    ThemeMode themeMode = ThemeMode.light,
    FakeMenuService? fakeService,
  }) {
    final service = fakeService ?? FakeMenuService();
    return ProviderScope(
      overrides: [
        menuServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(
          body: MenuItemForm(
            item: item,
            onSave: onSave,
          ),
        ),
      ),
    );
  }

  const sampleItem = MenuItem(
    id: 'test-item-1',
    name: 'Spicy Paneer Pizza',
    subtitle: 'Fresh cottage cheese with red chilies and bell peppers',
    price: 349.0,
    categorySlug: 'pizza',
    type: 'veg',
    featured: true,
    available: true,
  );

  group('MenuItemForm Widget Tests (Task 2A-3)', () {
    testWidgets('Renders create mode with empty fields and sensible defaults',
        (tester) async {
      await tester.pumpWidget(buildTestForm());
      await tester.pumpAndSettle();

      // Title & CTA
      expect(find.text('New Menu Item'), findsOneWidget);
      expect(find.text('Add to Menu'), findsOneWidget);

      // Verify fields in sequence
      expect(find.byKey(const Key('menu_form_name_field')), findsOneWidget);
      expect(find.byKey(const Key('menu_form_subtitle_field')), findsOneWidget);
      expect(find.byKey(const Key('menu_form_price_field')), findsOneWidget);
      expect(find.byKey(const Key('menu_form_category_picker')), findsOneWidget);
      expect(find.byKey(const Key('menu_form_type_toggle')), findsOneWidget);
      expect(find.byKey(const Key('menu_form_featured_switch')), findsOneWidget);
      expect(find.byKey(const Key('menu_form_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('menu_form_cancel_button')), findsOneWidget);

      // Default values
      final nameField =
          tester.widget<TextField>(find.byKey(const Key('menu_form_name_field')));
      expect(nameField.controller?.text, isEmpty);

      final priceField = tester
          .widget<TextField>(find.byKey(const Key('menu_form_price_field')));
      expect(priceField.controller?.text, isEmpty);

      final featuredSwitch =
          tester.widget<Switch>(find.byKey(const Key('menu_form_featured_switch')));
      expect(featuredSwitch.value, isFalse);

      // PRD A-16: NO image upload or picker anywhere
      expect(find.textContaining('image', findRichText: true), findsNothing);
      expect(find.textContaining('photo', findRichText: true), findsNothing);
      expect(find.textContaining('upload', findRichText: true), findsNothing);
    });

    testWidgets('Renders edit mode pre-filled with existing item data',
        (tester) async {
      await tester.pumpWidget(buildTestForm(item: sampleItem));
      await tester.pumpAndSettle();

      // Title & CTA
      expect(find.text('Edit Menu Item'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Pre-filled fields
      expect(find.text('Spicy Paneer Pizza'), findsOneWidget);
      expect(find.text('Fresh cottage cheese with red chilies and bell peppers'),
          findsOneWidget);
      expect(find.text('349'), findsOneWidget);

      final featuredSwitch =
          tester.widget<Switch>(find.byKey(const Key('menu_form_featured_switch')));
      expect(featuredSwitch.value, isTrue);
    });

    testWidgets('Shows inline validation error when required fields are empty',
        (tester) async {
      await tester.pumpWidget(buildTestForm());
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('menu_form_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.pumpAndSettle();

      // Attempt to submit empty form
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      // Inline validation messages
      expect(find.text('Please enter an item name.'), findsOneWidget);
      expect(find.text('Please enter a price.'), findsOneWidget);
    });

    testWidgets('Validates that price must be positive and non-zero',
        (tester) async {
      await tester.pumpWidget(buildTestForm());
      await tester.pumpAndSettle();

      // Enter valid name, but price 0
      await tester.enterText(
          find.byKey(const Key('menu_form_name_field')), 'Test Item');
      await tester.enterText(
          find.byKey(const Key('menu_form_price_field')), '0');
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('menu_form_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.pumpAndSettle();

      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Please enter an item name.'), findsNothing);
      expect(
          find.text('Please enter a valid price greater than ₹0.'), findsOneWidget);
    });

    testWidgets('Toggles dietary preference between Veg and Non-Veg',
        (tester) async {
      await tester.pumpWidget(buildTestForm());
      await tester.pumpAndSettle();

      final vegFinder = find.byKey(const Key('menu_form_type_veg'));
      final nonVegFinder = find.byKey(const Key('menu_form_type_non_veg'));

      await tester.ensureVisible(vegFinder);
      await tester.pumpAndSettle();

      // Tap Non-Veg
      await tester.tap(nonVegFinder);
      await tester.pumpAndSettle();

      // Tap Veg back
      await tester.tap(vegFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('Toggles featured switch', (tester) async {
      await tester.pumpWidget(buildTestForm());
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('menu_form_featured_switch'));
      await tester.ensureVisible(switchFinder);
      await tester.pumpAndSettle();

      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);
    });

    testWidgets(
        'Submitting valid form shows loading state and calls onSave callback',
        (tester) async {
      MenuItem? savedResult;
      await tester.pumpWidget(
        buildTestForm(
          onSave: (item) => savedResult = item,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('menu_form_name_field')), 'Garlic Breadstick');
      await tester.enterText(find.byKey(const Key('menu_form_subtitle_field')),
          'Warm buttery bread');
      await tester.enterText(
          find.byKey(const Key('menu_form_price_field')), '149');
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('menu_form_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.pumpAndSettle();

      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(savedResult!.name, 'Garlic Breadstick');
      expect(savedResult!.subtitle, 'Warm buttery bread');
      expect(savedResult!.price, 149.0);
      expect(savedResult!.available, isTrue);
    });

    testWidgets(
        'Server validation failure for category displays inline error under category field',
        (tester) async {
      final fakeService = FakeMenuService(
        shouldCreateFail: true,
        createErrorMessage: "Category with slug 'pizza' does not exist.",
      );

      await tester.pumpWidget(buildTestForm(fakeService: fakeService));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('menu_form_name_field')), 'Custom Pizza');
      await tester.enterText(
          find.byKey(const Key('menu_form_price_field')), '299');
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('menu_form_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(
        find.text("Category with slug 'pizza' does not exist."),
        findsOneWidget,
      );
    });

    testWidgets(
        'Server validation failure for name displays inline error under name field',
        (tester) async {
      final fakeService = FakeMenuService(
        shouldCreateFail: true,
        createErrorMessage: "Field 'name' is required and must be a non-empty string.",
      );

      await tester.pumpWidget(buildTestForm(fakeService: fakeService));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('menu_form_name_field')), 'Valid on Client');
      await tester.enterText(
          find.byKey(const Key('menu_form_price_field')), '99');
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('menu_form_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(
        find.text("Field 'name' is required and must be a non-empty string."),
        findsOneWidget,
      );
    });

    testWidgets(
        'Server general validation error displays inline banner above submit button',
        (tester) async {
      final fakeService = FakeMenuService(
        shouldCreateFail: true,
        createErrorMessage: 'Invalid menu item configuration.',
      );

      await tester.pumpWidget(buildTestForm(fakeService: fakeService));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('menu_form_name_field')), 'Valid Item');
      await tester.enterText(
          find.byKey(const Key('menu_form_price_field')), '99');
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('menu_form_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_form_general_error')), findsOneWidget);
      expect(find.text('Invalid menu item configuration.'), findsOneWidget);
    });

    testWidgets(
        'Submitting edit form calls updateMenuItem and passes updated item',
        (tester) async {
      MenuItem? updatedResult;
      await tester.pumpWidget(
        buildTestForm(
          item: sampleItem,
          onSave: (item) => updatedResult = item,
        ),
      );
      await tester.pumpAndSettle();

      // Change price
      final priceFinder = find.byKey(const Key('menu_form_price_field'));
      await tester.enterText(priceFinder, '399');
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('menu_form_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(updatedResult, isNotNull);
      expect(updatedResult!.id, sampleItem.id);
      expect(updatedResult!.price, 399.0);
    });

    testWidgets('Supports dark mode rendering without issue', (tester) async {
      await tester.pumpWidget(buildTestForm(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('New Menu Item'), findsOneWidget);
      expect(find.byKey(const Key('menu_form_name_field')), findsOneWidget);
    });
  });

  group('MenuItemForm Category Picker Tests (Task 2B-5)', () {
    testWidgets('Renders real categories with icons from categoriesProvider',
        (tester) async {
      await tester.pumpWidget(buildTestForm());
      await tester.pumpAndSettle();

      final pickerFinder = find.byKey(const Key('menu_form_category_picker'));
      expect(pickerFinder, findsOneWidget);

      // Tap picker to open dropdown menu
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();

      // Confirm categories from testCategories appear with their icons
      expect(find.text('🍕  Pizza'), findsWidgets);
      expect(find.text('🍔  Burger'), findsWidgets);
      expect(find.text('🍟  Sides'), findsWidgets);
      expect(find.text('🥤  Drinks'), findsWidgets);
      expect(find.text('🍰  Dessert'), findsWidgets);
    });

    testWidgets('Pre-selects existing item category in edit mode',
        (tester) async {
      const burgerItem = MenuItem(
        id: 'item-burger',
        name: 'Classic Smash Burger',
        subtitle: 'Juicy burger',
        price: 199.0,
        categorySlug: 'burger',
        type: 'non-veg',
      );

      await tester.pumpWidget(buildTestForm(item: burgerItem));
      await tester.pumpAndSettle();

      // Selected value in DropdownButtonFormField should display Burger
      expect(find.text('🍔  Burger'), findsOneWidget);
    });

    testWidgets('Displays fallback category if editing item with legacy category',
        (tester) async {
      const customItem = MenuItem(
        id: 'item-custom',
        name: 'Chef Special',
        subtitle: 'Special dish',
        price: 299.0,
        categorySlug: 'specials',
        type: 'veg',
      );

      await tester.pumpWidget(buildTestForm(item: customItem));
      await tester.pumpAndSettle();

      expect(find.text('Specials'), findsOneWidget);
    });

    testWidgets('Displays error state with retry button on category load failure',
        (tester) async {
      final fakeService = FakeMenuService(
        shouldGetCategoriesFail: true,
        getCategoriesErrorMessage: 'Categories service unavailable',
      );

      await tester.pumpWidget(buildTestForm(fakeService: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load categories'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      // Now fix service and tap retry
      fakeService.shouldGetCategoriesFail = false;
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load categories'), findsNothing);
      expect(find.text('🍕  Pizza'), findsOneWidget);
    });

    testWidgets('Changing category selects and saves with new categorySlug',
        (tester) async {
      MenuItem? savedResult;
      await tester.pumpWidget(
        buildTestForm(
          onSave: (item) => savedResult = item,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('menu_form_name_field')), 'Virgin Mojito');
      await tester.enterText(
          find.byKey(const Key('menu_form_price_field')), '129');
      await tester.pumpAndSettle();

      // Open category picker and select Drinks
      final pickerFinder = find.byKey(const Key('menu_form_category_picker'));
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();

      // Tap Drinks in the popup dropdown
      final drinksOption = find.text('🥤  Drinks').last;
      await tester.tap(drinksOption);
      await tester.pumpAndSettle();

      // Submit form
      final submitFinder = find.byKey(const Key('menu_form_submit_button'));
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(savedResult!.name, 'Virgin Mojito');
      expect(savedResult!.categorySlug, 'drinks');
    });
  });
}
