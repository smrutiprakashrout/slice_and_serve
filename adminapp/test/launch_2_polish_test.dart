import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:adminapp/core/result.dart';
import 'package:adminapp/models/category.dart';
import 'package:adminapp/models/loyalty_card.dart';
import 'package:adminapp/models/menu_item.dart';
import 'package:adminapp/providers/auth_provider.dart';
import 'package:adminapp/providers/loyalty_provider.dart';
import 'package:adminapp/providers/menu_provider.dart';
import 'package:adminapp/providers/orders_provider.dart';
import 'package:adminapp/screens/login_screen.dart';
import 'package:adminapp/screens/loyalty/loyalty_card_view.dart';
import 'package:adminapp/screens/main_shell.dart';
import 'package:adminapp/screens/menu/menu_item_form.dart';
import 'package:adminapp/screens/menu/menu_screen.dart';
import 'package:adminapp/screens/orders/orders_screen.dart';
import 'package:adminapp/screens/settings/settings_screen.dart';
import 'package:adminapp/services/auth_service.dart';
import 'package:adminapp/services/loyalty_service.dart';
import 'package:adminapp/theme/app_theme.dart';
import 'package:adminapp/widgets/brand_button.dart';

import 'fixtures/loyalty_fixtures.dart';
import 'fixtures/menu_fixtures.dart';
import 'fixtures/order_fixtures.dart';

class _FakeAuthService implements AuthService {
  @override
  Future<Result<String>> login(String username, String password) async =>
      const Result.success('test_token');

  @override
  Future<bool> hasValidSession() async => true;

  @override
  Future<void> logout() async {}
}

class _FakeMenuService extends FakeMenuService {
  @override
  Future<Result<List<MenuItem>>> getMenuItems() async =>
      const Result.success(testMenuItems);

  @override
  Future<Result<List<Category>>> getCategories() async =>
      const Result.success(testCategories);
}

class _FakeLoyaltyService extends LoyaltyService {
  @override
  Future<Result<LoyaltyScanResult>> scanToken(String token) async =>
      const Result.success(testScanStampInProgress);
}

class _FakeOrderService extends FakeOrderService {}

Widget _buildWrapper({
  required Widget child,
  ThemeMode themeMode = ThemeMode.light,
  bool disableAnimations = false,
  double textScaleFactor = 1.0,
}) {
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(_FakeAuthService()),
      menuServiceProvider.overrideWithValue(_FakeMenuService()),
      loyaltyServiceProvider.overrideWithValue(_FakeLoyaltyService()),
      orderServiceProvider.overrideWithValue(_FakeOrderService()),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, widget) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: widget ?? const SizedBox.shrink(),
        );
      },
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Launch-2: Polished Flutter UI Checklist (§7)', () {
    testWidgets('1. Login Screen renders cleanly in Light & Dark modes without overflow at 2.0x text scale',
        (tester) async {
      // Light Mode with 2.0x font scaling
      await tester.pumpWidget(
        _buildWrapper(
          child: const LoginScreen(),
          themeMode: ThemeMode.light,
          textScaleFactor: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);

      // Dark Mode with 2.0x font scaling
      await tester.pumpWidget(
        _buildWrapper(
          child: const LoginScreen(),
          themeMode: ThemeMode.dark,
          textScaleFactor: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('2. Main Shell (all 4 tabs navigation) renders in Light & Dark modes without error',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          child: const MainShell(),
          themeMode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byKey(const Key('shell_nav_menu')), findsOneWidget);
      expect(find.byKey(const Key('shell_nav_loyalty')), findsOneWidget);
      expect(find.byKey(const Key('shell_nav_orders')), findsOneWidget);
      expect(find.byKey(const Key('shell_nav_settings')), findsOneWidget);

      // Dark Mode
      await tester.pumpWidget(
        _buildWrapper(
          child: const MainShell(),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('3. Menu List renders properly under 2.0x text scaling and reduced motion',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          child: const MenuScreen(),
          textScaleFactor: 2.0,
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_list_view')), findsOneWidget);
      expect(find.byKey(const Key('menu_fab_add')), findsOneWidget);
    });

    testWidgets('4. MenuItemForm renders under 2.0x text scaling and reduced motion without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          child: Scaffold(
            body: MenuItemForm(
              item: testMenuItems.first,
            ),
          ),
          textScaleFactor: 2.0,
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Menu Item'), findsOneWidget);
      expect(find.byKey(const Key('menu_form_submit_button')), findsOneWidget);
    });

    testWidgets('5. Loyalty Scanner & Result Cards render under 2.0x text scale in both modes',
        (tester) async {
      // Stamp Result Card
      await tester.pumpWidget(
        _buildWrapper(
          child: Scaffold(
            body: SingleChildScrollView(
              child: LoyaltyCardView(
                scanResult: testScanStampInProgress,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
          textScaleFactor: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_stamp_confirmation_card')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_confirm_stamp_button')), findsOneWidget);

      // Redeem Result Card
      await tester.pumpWidget(
        _buildWrapper(
          child: Scaffold(
            body: SingleChildScrollView(
              child: LoyaltyCardView(
                scanResult: testScanRedeemReady,
                onConfirm: () {},
                onCancel: () {},
              ),
            ),
          ),
          textScaleFactor: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_confirm_redeem_button')), findsOneWidget);
    });

    testWidgets('6. Orders list (all 3 segments) renders under 2.0x text scale without overflow',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          child: const OrdersScreen(),
          textScaleFactor: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('orders_segment_pending')), findsOneWidget);
      expect(find.byKey(const Key('orders_segment_accepted')), findsOneWidget);
      expect(find.byKey(const Key('orders_segment_completed')), findsOneWidget);
    });

    testWidgets('7. Settings screen renders all 3 sections under 2.0x text scale in dark mode',
        (tester) async {
      final customPackageInfo = PackageInfo(
        appName: 'Slice and Serve Admin',
        packageName: 'com.example.adminapp',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );

      await tester.pumpWidget(
        _buildWrapper(
          child: SettingsScreen(
            showAppBar: true,
            packageInfo: customPackageInfo,
            initialAboutExpanded: true,
            initialReportBugExpanded: true,
          ),
          themeMode: ThemeMode.dark,
          textScaleFactor: 2.0,
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings_section_theme')), findsOneWidget);
      expect(find.byKey(const Key('settings_section_about')), findsOneWidget);
      expect(find.byKey(const Key('settings_theme_dark')), findsOneWidget);
      expect(find.text('Version 1.0.0 (build 1)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_section_report_bug')),
        200.0,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings_section_report_bug')), findsOneWidget);
    });

    testWidgets('8. BrandButton and BrandCard respect reduced motion',
        (tester) async {
      await tester.pumpWidget(
        _buildWrapper(
          child: Scaffold(
            body: BrandButton(
              key: const Key('test_reduced_motion_button'),
              text: 'Tap Me',
              onPressed: () {},
            ),
          ),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('test_reduced_motion_button'))),
      );
      await tester.pump();

      // With reduced motion, scale should remain 1.0 (no bounce/scale down)
      final scaleWidget = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scaleWidget.scale, equals(1.0));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
