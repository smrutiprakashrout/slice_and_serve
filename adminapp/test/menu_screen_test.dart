import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/providers/menu_provider.dart';
import 'package:adminapp/screens/menu/menu_item_form.dart';
import 'package:adminapp/screens/menu/menu_screen.dart';
import 'package:adminapp/services/menu_service.dart';
import 'package:adminapp/theme/app_theme.dart';
import 'package:adminapp/widgets/confirmation_dialog.dart';
import 'fixtures/menu_fixtures.dart';

void main() {
  Widget buildTestMenuScreen({
    ThemeMode themeMode = ThemeMode.light,
    MenuViewMode initialViewMode = MenuViewMode.list,
    MenuService? menuService,
  }) {
    final service = menuService ?? FakeMenuService();
    return ProviderScope(
      overrides: [
        menuServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(
          body: MenuScreen(
            initialViewMode: initialViewMode,
          ),
        ),
      ),
    );
  }

  group('MenuScreen Widget Tests (Tasks 2A-2 & 2B-1)', () {
    testWidgets('Renders all mock menu items with titles, prices, and tags',
        (tester) async {
      await tester.pumpWidget(buildTestMenuScreen());
      await tester.pumpAndSettle();

      // Top active count header
      final initialActiveCount =
          testMenuItems.where((item) => item.available).length;
      expect(find.text('$initialActiveCount/${testMenuItems.length} Active'),
          findsOneWidget);

      // Verify mode selector chips
      expect(find.byKey(const Key('menu_view_mode_list')), findsOneWidget);
      expect(find.byKey(const Key('menu_view_mode_loading')), findsOneWidget);
      expect(find.byKey(const Key('menu_view_mode_empty')), findsOneWidget);

      // Verify items from testMenuItems appear in list
      expect(find.text('Margherita Classic Pizza'), findsOneWidget);
      expect(find.text('₹249'), findsOneWidget);
      expect(find.text('Double Cheese Burst Pizza'), findsOneWidget);
      expect(find.text('₹329'), findsOneWidget);

      // Verify dietary & featured tags are rendered
      expect(find.text('VEG'), findsWidgets);
      expect(find.text('FEATURED'), findsWidgets);

      // FAB is present
      expect(find.byKey(const Key('menu_fab_add')), findsOneWidget);
    });

    testWidgets(
        'Toggling availability switch updates local state and active counter',
        (tester) async {
      await tester.pumpWidget(buildTestMenuScreen());
      await tester.pumpAndSettle();

      final initialActiveCount =
          testMenuItems.where((item) => item.available).length;
      expect(find.text('$initialActiveCount/${testMenuItems.length} Active'),
          findsOneWidget);

      // Find switch for first item (menu-1: Margherita Classic Pizza, initially available: true)
      final switchFinder = find.byKey(const Key('menu_switch_menu-1'));
      expect(switchFinder, findsOneWidget);

      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // Toggle off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);

      // Active count should decrement by 1
      expect(
          find.text('${initialActiveCount - 1}/${testMenuItems.length} Active'),
          findsOneWidget);

      // Toggle back on
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);
      expect(find.text('$initialActiveCount/${testMenuItems.length} Active'),
          findsOneWidget);
    });

    testWidgets(
        'Toggling availability switch rolls back on server failure and displays branded error snackbar',
        (tester) async {
      final fakeService = FakeMenuService(
        shouldSetAvailabilityFail: true,
        setAvailabilityErrorMessage: 'Database connection failed.',
      );

      await tester.pumpWidget(buildTestMenuScreen(menuService: fakeService));
      await tester.pumpAndSettle();

      final switchFinder = find.byKey(const Key('menu_switch_menu-1'));
      expect(switchFinder, findsOneWidget);

      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // Tap switch to toggle off
      await tester.tap(switchFinder);
      // Wait for async call to complete and settle UI
      await tester.pumpAndSettle();

      // Switch should have rolled back to true
      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // Branded error snackbar should be displayed with error message
      expect(
        find.text('Failed to update availability: Database connection failed.'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Empty mode chip displays empty state view',
        (tester) async {
      await tester.pumpWidget(buildTestMenuScreen());
      await tester.pumpAndSettle();

      // Switch to empty mode
      await tester.tap(find.byKey(const Key('menu_view_mode_empty')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_empty_view')), findsOneWidget);
      expect(find.text('No Menu Items Found'), findsOneWidget);
      expect(find.byKey(const Key('menu_empty_reload_button')), findsOneWidget);

      // Tapping reload restores list mode
      await tester.tap(find.byKey(const Key('menu_empty_reload_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_empty_view')), findsNothing);
      expect(find.text('Margherita Classic Pizza'), findsOneWidget);
    });

    testWidgets('Tapping Loading mode chip displays shimmer skeleton cards',
        (tester) async {
      await tester.pumpWidget(buildTestMenuScreen());
      await tester.pumpAndSettle();

      // Switch to loading mode
      await tester.tap(find.byKey(const Key('menu_view_mode_loading')));
      await tester.pump();
      // Pump for duration of AnimatedSwitcher (300ms) plus unmount frame
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      expect(find.byKey(const Key('menu_loading_skeleton_view')), findsOneWidget);
      expect(find.text('Margherita Classic Pizza'), findsNothing);

      // Switch back to list mode
      await tester.tap(find.byKey(const Key('menu_view_mode_list')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_loading_skeleton_view')), findsNothing);
      expect(find.text('Margherita Classic Pizza'), findsOneWidget);
    });

    testWidgets('Tapping FAB opens create form sheet', (tester) async {
      await tester.pumpWidget(buildTestMenuScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('menu_fab_add')));
      await tester.pumpAndSettle();

      expect(find.byType(MenuItemForm), findsOneWidget);
      expect(find.text('New Menu Item'), findsOneWidget);
      expect(find.byKey(const Key('menu_form_submit_button')), findsOneWidget);
    });

    testWidgets('Tapping menu item card opens edit form sheet pre-filled',
        (tester) async {
      await tester.pumpWidget(buildTestMenuScreen());
      await tester.pumpAndSettle();

      // Tap first item card
      await tester.tap(find.text('Margherita Classic Pizza'));
      await tester.pumpAndSettle();

      expect(find.byType(MenuItemForm), findsOneWidget);
      expect(find.text('Edit Menu Item'), findsOneWidget);
      expect(find.text('Margherita Classic Pizza'), findsWidgets);
      expect(find.text('249'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Pull to refresh completes and displays feedback snackbar',
        (tester) async {
      await tester.pumpWidget(buildTestMenuScreen());
      await tester.pumpAndSettle();

      // Drag list down to trigger RefreshIndicator
      await tester.fling(
        find.text('Margherita Classic Pizza'),
        const Offset(0.0, 300.0),
        1000.0,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Menu refreshed'), findsOneWidget);
    });

    testWidgets('Renders cleanly in dark mode theme', (tester) async {
      await tester.pumpWidget(buildTestMenuScreen(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Margherita Classic Pizza'), findsOneWidget);
      expect(find.byKey(const Key('menu_fab_add')), findsOneWidget);
    });

    testWidgets('Swiping item left triggers destructive confirmation dialog',
        (tester) async {
      await tester.pumpWidget(buildTestMenuScreen());
      await tester.pumpAndSettle();

      // Swipe left on item
      await tester.drag(
        find.byKey(const Key('menu_dismissible_menu-1')),
        const Offset(-500.0, 0.0),
      );
      await tester.pumpAndSettle();

      // Confirmation dialog should be presented
      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(find.text('Delete "Margherita Classic Pizza"?'), findsOneWidget);

      // Cancel deletion
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed, item remains intact
      expect(find.byType(ConfirmationDialog), findsNothing);
      expect(find.text('Margherita Classic Pizza'), findsOneWidget);
    });

    testWidgets(
        'Confirming delete removes item immediately and updates active counter',
        (tester) async {
      await tester.pumpWidget(buildTestMenuScreen());
      await tester.pumpAndSettle();

      final initialActiveCount =
          testMenuItems.where((item) => item.available).length;

      // Swipe left on first item
      await tester.drag(
        find.byKey(const Key('menu_dismissible_menu-1')),
        const Offset(-500.0, 0.0),
      );
      await tester.pumpAndSettle();

      // Tap destructive delete button inside ConfirmationDialog
      final dialogDeleteButton = find.descendant(
        of: find.byType(ConfirmationDialog),
        matching: find.text('Delete'),
      );
      await tester.tap(dialogDeleteButton);
      await tester.pumpAndSettle();

      // Dialog dismissed, item removed from list
      expect(find.byType(ConfirmationDialog), findsNothing);
      expect(find.text('Margherita Classic Pizza'), findsNothing);
      expect(
        find.text(
            '${initialActiveCount - 1}/${testMenuItems.length - 1} Active'),
        findsOneWidget,
      );
      expect(find.text('Deleted "Margherita Classic Pizza"'), findsOneWidget);
    });

    testWidgets(
        'Long pressing item card opens destructive delete confirmation and removes item on confirm',
        (tester) async {
      await tester.pumpWidget(buildTestMenuScreen());
      await tester.pumpAndSettle();

      // Long press second item (menu-2: Double Cheese Burst Pizza)
      await tester.longPress(find.text('Double Cheese Burst Pizza'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be presented
      expect(find.byType(ConfirmationDialog), findsOneWidget);
      expect(
          find.text('Delete "Double Cheese Burst Pizza"?'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Item removed smoothly
      expect(find.byType(ConfirmationDialog), findsNothing);
      expect(find.text('Double Cheese Burst Pizza'), findsNothing);
      expect(find.text('Deleted "Double Cheese Burst Pizza"'), findsOneWidget);
    });

    testWidgets('Displays error view with retry button on network error',
        (tester) async {
      final failingService = FakeMenuService(
        shouldFail: true,
        errorMessage: 'Connection timed out',
      );

      await tester.pumpWidget(
        buildTestMenuScreen(menuService: failingService),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_error_view')), findsOneWidget);
      expect(find.text('Unable to Load Menu'), findsOneWidget);
      expect(find.text('Connection timed out'), findsOneWidget);
      expect(find.byKey(const Key('menu_error_retry_button')), findsOneWidget);

      // Switch failing service to succeeding
      failingService.shouldFail = false;
      await tester.tap(find.byKey(const Key('menu_error_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_error_view')), findsNothing);
      expect(find.text('Margherita Classic Pizza'), findsOneWidget);
    });

    testWidgets(
        'Server delete failure preserves item in list and displays error snackbar',
        (tester) async {
      final failingService = FakeMenuService(
        shouldDeleteFail: true,
        deleteErrorMessage: 'Failed to delete item from database.',
      );

      await tester.pumpWidget(
        buildTestMenuScreen(menuService: failingService),
      );
      await tester.pumpAndSettle();

      // Swipe left on first item (menu-1)
      await tester.drag(
        find.byKey(const Key('menu_dismissible_menu-1')),
        const Offset(-500.0, 0.0),
      );
      await tester.pumpAndSettle();

      // Tap destructive delete button inside ConfirmationDialog
      final dialogDeleteButton = find.descendant(
        of: find.byType(ConfirmationDialog),
        matching: find.text('Delete'),
      );
      await tester.tap(dialogDeleteButton);
      await tester.pumpAndSettle();

      // Dialog dismissed, error snackbar displayed
      expect(find.byType(ConfirmationDialog), findsNothing);
      expect(find.text('Failed to delete item from database.'), findsOneWidget);

      // Item is NOT removed from list
      expect(find.text('Margherita Classic Pizza'), findsOneWidget);
    });
  });
}
