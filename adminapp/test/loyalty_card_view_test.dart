import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/models/loyalty_card.dart';
import 'package:adminapp/screens/loyalty/loyalty_card_view.dart';
import 'package:adminapp/theme/app_theme.dart';
import 'fixtures/loyalty_fixtures.dart';

void main() {
  Widget buildTestCard({
    required LoyaltyScanResult scanResult,
    ThemeMode themeMode = ThemeMode.light,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return MaterialApp(
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: SingleChildScrollView(
          child: LoyaltyCardView(
            scanResult: scanResult,
            onConfirm: onConfirm ?? () {},
            onCancel: onCancel ?? () {},
          ),
        ),
      ),
    );
  }

  group('LoyaltyCardView Widget Tests (Task 3A-3)', () {
    testWidgets('Renders stamp confirmation card with customer info and progress',
        (tester) async {
      bool confirmed = false;
      bool cancelled = false;

      await tester.pumpWidget(
        buildTestCard(
          scanResult: mockScanStampInProgress,
          onConfirm: () => confirmed = true,
          onCancel: () => cancelled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Card structure
      expect(find.byKey(const Key('loyalty_stamp_confirmation_card')),
          findsOneWidget);
      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')),
          findsNothing);
      expect(find.text('ADD STAMP'), findsOneWidget);

      // Customer info
      expect(find.byKey(const Key('loyalty_customer_name')), findsOneWidget);
      expect(find.text('Aarav Mehta'), findsOneWidget);
      expect(find.text('Customer ID: cust_aarav_001'), findsOneWidget);

      // Progress representation: 6 of 10 stamps
      expect(find.text('6'), findsOneWidget);
      expect(find.text(' of 10 stamps'), findsOneWidget);
      expect(find.text('+1 stamp pending'), findsOneWidget);

      // Confirm button
      final confirmBtn = find.byKey(const Key('loyalty_confirm_stamp_button'));
      expect(confirmBtn, findsOneWidget);
      expect(find.text('Confirm Stamp'), findsOneWidget);

      // Tap confirm
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);

      // Tap close/cancel button
      final closeBtn = find.byKey(const Key('loyalty_card_close_button'));
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
    });

    testWidgets('Renders stamp card that completes the card with badge',
        (tester) async {
      await tester.pumpWidget(
        buildTestCard(scanResult: mockScanStampCompletes),
      );
      await tester.pumpAndSettle();

      expect(find.text('Riya Sharma'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('🎉 Completes card!'), findsOneWidget);
      expect(find.text('Confirm Stamp (Completes Card)'), findsOneWidget);
    });

    testWidgets('Renders redeem confirmation card with celebratory treatment',
        (tester) async {
      bool redeemConfirmed = false;
      bool redeemCancelled = false;

      await tester.pumpWidget(
        buildTestCard(
          scanResult: mockScanRedeemReady,
          onConfirm: () => redeemConfirmed = true,
          onCancel: () => redeemCancelled = true,
        ),
      );
      await tester.pumpAndSettle();

      // Card structure: distinct from stamp
      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')),
          findsOneWidget);
      expect(find.byKey(const Key('loyalty_stamp_confirmation_card')),
          findsNothing);
      expect(find.text('REWARD READY!'), findsOneWidget);

      // Prominent customer info & celebration
      expect(find.text('Kabir Verma'), findsOneWidget);
      expect(find.text('Customer ID: cust_kabir_003'), findsOneWidget);
      expect(find.text('1x Free Artisan Pizza'), findsOneWidget);
      expect(find.text('Full 10/10 Stamp Card Reward'), findsOneWidget);

      // Caution notice
      expect(
        find.textContaining('Confirming will reset this card back to 0 stamps'),
        findsOneWidget,
      );

      // Deliberate, weightier confirm button
      final redeemBtn = find.byKey(const Key('loyalty_confirm_redeem_button'));
      expect(redeemBtn, findsOneWidget);
      expect(find.text('Confirm & Redeem Reward'), findsOneWidget);

      // Tap confirm redeem
      await tester.tap(redeemBtn);
      await tester.pumpAndSettle();
      expect(redeemConfirmed, isTrue);

      // Tap cancel button
      final cancelBtn = find.byKey(const Key('loyalty_cancel_redeem_button'));
      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();
      expect(redeemCancelled, isTrue);
    });

    testWidgets('Renders both cards cleanly in dark mode theme', (tester) async {
      await tester.pumpWidget(
        buildTestCard(
          scanResult: mockScanStampInProgress,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aarav Mehta'), findsOneWidget);

      await tester.pumpWidget(
        buildTestCard(
          scanResult: mockScanRedeemReady,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kabir Verma'), findsOneWidget);
      expect(find.text('REWARD READY!'), findsOneWidget);
    });
  });
}
