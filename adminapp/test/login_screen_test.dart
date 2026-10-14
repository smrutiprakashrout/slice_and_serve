import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/core/result.dart';
import 'package:adminapp/main.dart';
import 'package:adminapp/providers/auth_provider.dart';
import 'package:adminapp/providers/menu_provider.dart';
import 'package:adminapp/providers/orders_provider.dart';
import 'package:adminapp/screens/login_screen.dart';
import 'package:adminapp/services/auth_service.dart';
import 'package:adminapp/theme/app_theme.dart';
import 'package:adminapp/widgets/brand_button.dart';
import 'fixtures/menu_fixtures.dart';
import 'fixtures/order_fixtures.dart';

class FakeAuthService implements AuthService {
  final Map<String, String> credentials = {
    'admin': 'secret123',
  };
  String? currentToken;

  @override
  Future<Result<String>> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (credentials[username] == password) {
      currentToken = 'valid_token_xyz';
      return const Result.success('valid_token_xyz');
    }
    return const Result.failure(
      'Invalid username or password. Please try again.',
      statusCode: 401,
      errorCode: 'INVALID_CREDENTIALS',
    );
  }

  @override
  Future<bool> hasValidSession() async => currentToken != null;

  @override
  Future<void> logout() async {
    currentToken = null;
  }
}

void main() {
  Widget buildTestApp({
    ThemeMode themeMode = ThemeMode.light,
    VoidCallback? onToggleTheme,
    VoidCallback? onLoginSuccess,
    FakeAuthService? fakeAuthService,
  }) {
    final authService = fakeAuthService ?? FakeAuthService();
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
        menuServiceProvider.overrideWithValue(FakeMenuService()),
        orderServiceProvider.overrideWithValue(FakeOrderService()),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: LoginScreen(
          onToggleTheme: onToggleTheme,
          onLoginSuccess: onLoginSuccess,
        ),
      ),
    );
  }

  group('LoginScreen Widget Tests (Tasks 1A-1 & 1B-2)', () {
    testWidgets('Renders all login elements correctly', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Slice and Serve Admin'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byKey(const Key('login_username_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_toggle')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Verify NO forbidden links exist per PRD.md A-2
      expect(find.textContaining('Forgot password', findRichText: true),
          findsNothing);
      expect(find.textContaining('Sign up', findRichText: true), findsNothing);
      expect(find.textContaining('Remember me', findRichText: true),
          findsNothing);
    });

    testWidgets('Toggles password visibility when eye icon is pressed',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final passwordFieldFinder = find.byKey(const Key('login_password_field'));
      final toggleFinder = find.byKey(const Key('login_password_toggle'));

      // Initially obscured
      TextField passwordField = tester.widget(passwordFieldFinder);
      expect(passwordField.obscureText, isTrue);

      // Tap toggle
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      passwordField = tester.widget(passwordFieldFinder);
      expect(passwordField.obscureText, isFalse);

      // Tap toggle again to re-obscure
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      passwordField = tester.widget(passwordFieldFinder);
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('Submitting with empty username shows validation error banner',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('login_submit_button'));
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.text('Please enter your username.'), findsOneWidget);
    });

    testWidgets('Submitting with empty password shows validation error banner',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('login_username_field')), 'admin');
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('login_submit_button'));
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets(
        'Submitting invalid credentials shows loading state then inline error',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('login_username_field')), 'admin');
      await tester.enterText(
          find.byKey(const Key('login_password_field')), 'wrong_pass');
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('login_submit_button'));
      await tester.tap(submitFinder);

      // Immediately after submit, loading state is active
      await tester.pump(const Duration(milliseconds: 50));
      final brandButton = tester.widget<BrandButton>(submitFinder);
      expect(brandButton.isLoading, isTrue);

      // Fast forward past auth delay
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Loading state cleared, error banner visible
      final buttonAfter = tester.widget<BrandButton>(submitFinder);
      expect(buttonAfter.isLoading, isFalse);
      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.text('Invalid username or password. Please try again.'),
          findsOneWidget);
    });

    testWidgets(
        'Submitting valid credentials succeeds and navigates to MainShell',
        (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('login_username_field')), 'admin');
      await tester.enterText(
          find.byKey(const Key('login_password_field')), 'secret123');
      await tester.pumpAndSettle();

      final submitFinder = find.byKey(const Key('login_submit_button'));
      await tester.tap(submitFinder);

      // Loading state visible
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.widget<BrandButton>(submitFinder).isLoading, isTrue);

      // Advance auth delay
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Main navigation shell reached with Menu tab active
      expect(find.byKey(const Key('shell_tab_menu_view')), findsOneWidget);
      expect(find.text('Margherita Classic Pizza'), findsOneWidget);
      expect(find.text('Menu'), findsWidgets);
      expect(find.text('Loyalty'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
    });

    testWidgets('Works seamlessly in dark mode theme', (tester) async {
      await tester.pumpWidget(buildTestApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets('Cold start with active session restores to MainShell directly',
        (tester) async {
      final fakeAuth = FakeAuthService()..currentToken = 'persisted_jwt';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(fakeAuth),
            menuServiceProvider.overrideWithValue(FakeMenuService()),
            orderServiceProvider.overrideWithValue(FakeOrderService()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: AuthGate(onToggleTheme: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // MainShell rendered directly
      expect(find.byKey(const Key('shell_tab_menu_view')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsNothing);
    });

    testWidgets('Cold start without session shows LoginScreen', (tester) async {
      final fakeAuth = FakeAuthService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(fakeAuth),
            menuServiceProvider.overrideWithValue(FakeMenuService()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: AuthGate(onToggleTheme: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Login screen rendered
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('shell_tab_menu_view')), findsNothing);
    });
  });
}
