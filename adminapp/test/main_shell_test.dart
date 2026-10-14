import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/providers/menu_provider.dart';
import 'package:adminapp/providers/orders_provider.dart';
import 'package:adminapp/screens/main_shell.dart';
import 'package:adminapp/theme/app_theme.dart';
import 'fixtures/menu_fixtures.dart';
import 'fixtures/order_fixtures.dart';

void main() {
  Widget buildTestShell({
    ThemeMode themeMode = ThemeMode.light,
    VoidCallback? onToggleTheme,
    int initialIndex = 0,
    FakeMenuService? fakeMenuService,
    FakeOrderService? fakeOrderService,
  }) {
    return ProviderScope(
      overrides: [
        menuServiceProvider.overrideWithValue(fakeMenuService ?? FakeMenuService()),
        orderServiceProvider.overrideWithValue(fakeOrderService ?? FakeOrderService()),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: MainShell(
          onToggleTheme: onToggleTheme,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  group('MainShell Navigation Tests', () {
    testWidgets(
        'Renders exactly four tabs in order: Menu, Loyalty, Orders (with badge), Settings',
        (tester) async {
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();

      // Verify four navigation destinations in order
      expect(find.byKey(const Key('shell_nav_menu')), findsOneWidget);
      expect(find.byKey(const Key('shell_nav_loyalty')), findsOneWidget);
      expect(find.byKey(const Key('shell_nav_orders')), findsOneWidget);
      expect(find.byKey(const Key('shell_nav_settings')), findsOneWidget);

      // Verify labels
      expect(find.text('Menu'), findsWidgets);
      expect(find.text('Loyalty'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify Orders tab shows badge count 3
      expect(
        find.descendant(
          of: find.byKey(const Key('shell_nav_orders')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );

      // Verify initial tab is Menu
      expect(find.text('Margherita Classic Pizza'), findsOneWidget);
      expect(find.byKey(const Key('shell_tab_menu_view')), findsOneWidget);
    });

    testWidgets('Tapping destinations switches between tabs smoothly via IndexedStack',
        (tester) async {
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();

      // Starts on Menu tab
      expect(find.text('Margherita Classic Pizza'), findsOneWidget);

      // Tap Loyalty tab
      await tester.tap(find.byKey(const Key('shell_nav_loyalty')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shell_tab_loyalty_view')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_mode_switch')), findsOneWidget);
      expect(find.text('Add Stamp'), findsOneWidget);
      expect(find.text('Redeem'), findsOneWidget);
      expect(find.text('Loyalty'), findsWidgets);

      // Tap Orders tab
      await tester.tap(find.byKey(const Key('shell_nav_orders')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shell_tab_orders_view')), findsOneWidget);
      expect(find.byKey(const Key('orders_segmented_control')), findsOneWidget);
      expect(find.text('Orders'), findsWidgets);

      // Tap Settings tab (Task 5A-1)
      await tester.tap(find.byKey(const Key('shell_nav_settings')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shell_tab_settings_view')), findsOneWidget);
      expect(find.byKey(const Key('settings_section_theme')), findsOneWidget);
      expect(find.byKey(const Key('settings_section_about')), findsOneWidget);
      expect(find.byKey(const Key('settings_section_report_bug')), findsOneWidget);
      expect(find.text('Settings'), findsWidgets);

      // Tap back to Menu tab
      await tester.tap(find.byKey(const Key('shell_nav_menu')));
      await tester.pumpAndSettle();

      expect(find.text('Margherita Classic Pizza'), findsOneWidget);
    });

    testWidgets('IndexedStack keeps all tab views mounted to preserve state',
        (tester) async {
      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();

      // All 4 tab views exist mounted in IndexedStack (inactive tabs are kept offstage)
      expect(
          find.byKey(const Key('shell_tab_menu_view'), skipOffstage: false),
          findsOneWidget);
      expect(
          find.byKey(const Key('shell_tab_loyalty_view'), skipOffstage: false),
          findsOneWidget);
      expect(
          find.byKey(const Key('shell_tab_orders_view'), skipOffstage: false),
          findsOneWidget);
      expect(
          find.byKey(const Key('shell_tab_settings_view'), skipOffstage: false),
          findsOneWidget);
    });

    testWidgets('Renders properly in dark mode theme', (tester) async {
      await tester.pumpWidget(buildTestShell(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shell_nav_menu')), findsOneWidget);
      expect(find.byKey(const Key('shell_nav_loyalty')), findsOneWidget);
      expect(find.byKey(const Key('shell_nav_orders')), findsOneWidget);
      expect(find.byKey(const Key('shell_nav_settings')), findsOneWidget);
      expect(find.text('Margherita Classic Pizza'), findsOneWidget);

      // Tap Settings in dark mode
      await tester.tap(find.byKey(const Key('shell_nav_settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shell_tab_settings_view')), findsOneWidget);
    });

    testWidgets('Orders tab hides badge when pending count is zero (Task 4B-3)', (tester) async {
      final fakeOrderService = FakeOrderService(
        initialOrders: [
          ...getMockOrdersByStatus('accepted'),
          ...getMockOrdersByStatus('completed'),
        ],
      );
      await tester.pumpWidget(buildTestShell(fakeOrderService: fakeOrderService));
      await tester.pumpAndSettle();

      // Badge label should not be visible when count is 0
      expect(find.text('0'), findsNothing);
    });

    testWidgets('Orders tab badge shows real count on launch and decrements on action (Task 4B-3)', (tester) async {
      final fakeOrderService = FakeOrderService();
      await tester.pumpWidget(buildTestShell(fakeOrderService: fakeOrderService));
      await tester.pumpAndSettle();

      // Initially shows real pending count: 3
      expect(
        find.descendant(
          of: find.byKey(const Key('shell_nav_orders')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );

      // Switch to Orders tab
      await tester.tap(find.byKey(const Key('shell_nav_orders')));
      await tester.pumpAndSettle();

      // Accept first pending order
      await tester.tap(find.text('Accept').first);
      await tester.pumpAndSettle();

      // Badge immediately decrements to 2 without restart or navigating away
      expect(
        find.descendant(
          of: find.byKey(const Key('shell_nav_orders')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });
  });
}
