import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:adminapp/core/result.dart';
import 'package:adminapp/models/loyalty_card.dart';
import 'package:adminapp/providers/loyalty_provider.dart';
import 'fixtures/loyalty_fixtures.dart';
import 'package:adminapp/screens/loyalty/loyalty_scanner_screen.dart';
import 'package:adminapp/services/loyalty_service.dart';
import 'package:adminapp/theme/app_theme.dart';

class FakeLoyaltyService extends LoyaltyService {
  Result<LoyaltyScanResult>? scanResultToReturn;
  Result<LoyaltyScanResult>? stampResultToReturn;
  Result<LoyaltyScanResult>? redeemResultToReturn;
  Future<Result<LoyaltyScanResult>> Function(String token)? customScanHandler;
  String? lastStampedCustomerId;
  String? lastRedeemedCustomerId;

  FakeLoyaltyService({
    this.scanResultToReturn,
    this.stampResultToReturn,
    this.redeemResultToReturn,
    this.customScanHandler,
  });

  @override
  Future<Result<LoyaltyScanResult>> scanToken(String token) async {
    if (customScanHandler != null) {
      return customScanHandler!(token);
    }
    if (scanResultToReturn != null) {
      return scanResultToReturn!;
    }
    if (token == '404_token' || token.contains('not_found')) {
      return const Result.failure(
        "This QR code doesn't match any customer. Ask the customer to pull up their loyalty card in the customer app.",
        statusCode: 404,
        errorCode: 'TOKEN_NOT_FOUND',
      );
    }
    if (token.contains('redeem')) {
      return const Result.success(
        LoyaltyScanResult(
          customerId: 'cust-2',
          customerName: 'Smrutiprakash Rout',
          stamps: 10,
          totalRequired: 10,
          rewardReady: true,
          action: 'redeem',
        ),
      );
    }
    return const Result.success(
      LoyaltyScanResult(
        customerId: 'cust-1',
        customerName: 'Smruti Rout',
        stamps: 2,
        totalRequired: 10,
        rewardReady: false,
        action: 'stamp',
      ),
    );
  }

  @override
  Future<Result<LoyaltyScanResult>> addStamp(
    String customerId, {
    LoyaltyScanResult? currentResult,
  }) async {
    lastStampedCustomerId = customerId;
    if (stampResultToReturn != null) {
      return stampResultToReturn!;
    }
    return Result.success(
      (currentResult ??
              const LoyaltyScanResult(
                customerId: 'cust-1',
                customerName: 'Smruti Rout',
                stamps: 2,
                totalRequired: 10,
                rewardReady: false,
                action: 'stamp',
              ))
          .copyWith(stamps: (currentResult?.stamps ?? 2) + 1),
    );
  }

  @override
  Future<Result<LoyaltyScanResult>> redeemReward(
    String customerId, {
    LoyaltyScanResult? currentResult,
  }) async {
    lastRedeemedCustomerId = customerId;
    if (redeemResultToReturn != null) {
      return redeemResultToReturn!;
    }
    return Result.success(
      (currentResult ??
              const LoyaltyScanResult(
                customerId: 'cust-2',
                customerName: 'Smrutiprakash Rout',
                stamps: 10,
                totalRequired: 10,
                rewardReady: true,
                action: 'redeem',
              ))
          .copyWith(stamps: 0, rewardReady: false),
    );
  }
}

void main() {
  Widget buildTestScreen({
    ThemeMode themeMode = ThemeMode.light,
    LoyaltyScanMode initialMode = LoyaltyScanMode.stamp,
    LoyaltyScanResult? initialScanResult,
    LoyaltyService? loyaltyService,
  }) {
    final service = loyaltyService ?? FakeLoyaltyService();
    return ProviderScope(
      overrides: [
        loyaltyServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: Scaffold(
          body: LoyaltyScannerScreen(
            initialMode: initialMode,
            initialScanResult: initialScanResult,
          ),
        ),
      ),
    );
  }

  group('LoyaltyScannerScreen Widget Tests (Tasks 3A-2 & 3A-3)', () {
    testWidgets('Renders mode switch, viewfinder placeholder, and instructions',
        (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Mode switch
      expect(find.byKey(const Key('loyalty_mode_switch')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_mode_stamp')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_mode_redeem')), findsOneWidget);
      expect(find.text('Add Stamp'), findsOneWidget);
      expect(find.text('Redeem'), findsOneWidget);

      // Viewfinder placeholder
      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.text('Camera Preview'), findsOneWidget);

      // Initial instructions for Stamp mode
      expect(find.byKey(const Key('loyalty_instruction_title')), findsOneWidget);
      expect(find.text('Scan to Add Stamp'), findsOneWidget);
      expect(find.byKey(const Key('loyalty_instruction_text')), findsOneWidget);
    });

    testWidgets('Tapping Redeem switches mode and updates instructions smoothly',
        (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Starts in Add Stamp mode
      expect(find.text('Scan to Add Stamp'), findsOneWidget);

      // Tap Redeem button
      await tester.tap(find.byKey(const Key('loyalty_mode_redeem')));
      await tester.pumpAndSettle();

      // Instructions update to Redeem mode
      expect(find.text('Scan to Redeem Reward'), findsOneWidget);

      // Tap Add Stamp button back
      await tester.tap(find.byKey(const Key('loyalty_mode_stamp')));
      await tester.pumpAndSettle();

      expect(find.text('Scan to Add Stamp'), findsOneWidget);
    });

    testWidgets('Stamp card confirm dismisses and returns cleanly to scanner',
        (tester) async {
      await tester.pumpWidget(
        buildTestScreen(initialScanResult: testScanStampInProgress),
      );
      await tester.pumpAndSettle();

      // Stamp confirmation card appears
      expect(find.byKey(const Key('loyalty_stamp_confirmation_card')), findsOneWidget);
      expect(find.text('Aarav Mehta'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.byKey(const Key('loyalty_confirm_stamp_button')), findsOneWidget);

      // Tap confirm button -> dismisses and returns to scanner
      final confirmBtn = find.byKey(const Key('loyalty_confirm_stamp_button'));
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_stamp_confirmation_card')), findsNothing);
    });

    testWidgets('Redeem card cancel dismisses and returns cleanly to scanner',
        (tester) async {
      await tester.pumpWidget(
        buildTestScreen(
          initialMode: LoyaltyScanMode.redeem,
          initialScanResult: testScanRedeemReady,
        ),
      );
      await tester.pumpAndSettle();

      // Redeem confirmation card appears with distinct celebratory UI
      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')), findsOneWidget);
      expect(find.text('Kabir Verma'), findsOneWidget);
      expect(find.text('REWARD READY!'), findsOneWidget);
      expect(find.byKey(const Key('loyalty_confirm_redeem_button')), findsOneWidget);

      // Tap cancel button -> dismisses and returns to scanner
      final cancelBtn = find.byKey(const Key('loyalty_cancel_redeem_button'));
      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')), findsNothing);
    });

    testWidgets('Scanning Redeem token in Stamp mode triggers mode mismatch error (PRD A-19)',
        (tester) async {
      final fakeService = FakeLoyaltyService(
        scanResultToReturn: const Result.success(testScanRedeemReady),
      );

      await tester.pumpWidget(buildTestScreen(loyaltyService: fakeService));
      await tester.pumpAndSettle();

      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      mobileScanner.onDetect?.call(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'mismatched_redeem_token')],
        ),
      );
      await tester.pumpAndSettle();

      // Mismatch error appears
      expect(find.byKey(const Key('loyalty_mismatch_error_view')), findsOneWidget);
      expect(find.text('Redeem Code Scanned'), findsOneWidget);
      expect(find.text('This code is for redeeming a reward, not adding a stamp.'), findsOneWidget);

      // Crucial: Result card is NEVER displayed!
      expect(find.byKey(const Key('loyalty_result_card_view')), findsNothing);
      expect(find.byKey(const Key('loyalty_stamp_confirmation_card')), findsNothing);
      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')), findsNothing);

      // Dismiss returns cleanly to scanner with mode unchanged
      final closeBtn = find.byKey(const Key('loyalty_mismatch_close_button'));
      await tester.ensureVisible(closeBtn);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_mismatch_error_view')), findsNothing);
      expect(find.text('Scan to Add Stamp'), findsOneWidget);
    });

    testWidgets('Scanning Stamp token in Redeem mode triggers mode mismatch error (PRD A-19)',
        (tester) async {
      final fakeService = FakeLoyaltyService(
        scanResultToReturn: const Result.success(testScanStampInProgress),
      );

      await tester.pumpWidget(buildTestScreen(
        initialMode: LoyaltyScanMode.redeem,
        loyaltyService: fakeService,
      ));
      await tester.pumpAndSettle();

      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      mobileScanner.onDetect?.call(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'stamp_token_on_redeem')],
        ),
      );
      await tester.pumpAndSettle();

      // Mismatch error displays plain-language reverse copy
      expect(find.byKey(const Key('loyalty_mismatch_error_view')), findsOneWidget);
      expect(find.text('Stamp Code Scanned'), findsOneWidget);
      expect(find.text('This code is for adding a stamp, not redeeming.'), findsOneWidget);
      expect(find.byKey(const Key('loyalty_result_card_view')), findsNothing);

      // Close button dismisses error
      final closeBtn = find.byKey(const Key('loyalty_mismatch_close_button'));
      await tester.ensureVisible(closeBtn);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.text('Scan to Redeem Reward'), findsOneWidget);
    });

    testWidgets('Confirming Stamp card shows celebratory success feedback with checkmark (PRD A-22)',
        (tester) async {
      await tester.pumpWidget(
        buildTestScreen(initialScanResult: testScanStampInProgress),
      );
      await tester.pumpAndSettle();

      // Tap Confirm Stamp
      final confirmBtn = find.byKey(const Key('loyalty_confirm_stamp_button'));
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);

      // Advance frames partially -> success feedback is showing!
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('loyalty_success_feedback_view')), findsOneWidget);
      expect(find.text('Stamp Added!'), findsOneWidget);

      // Let animation complete (<600ms) -> returns cleanly to scanner
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_success_feedback_view')), findsNothing);
      expect(find.text('Scan to Add Stamp'), findsOneWidget);
    });

    testWidgets('Confirming Redeem card shows celebratory success feedback (PRD A-22)',
        (tester) async {
      await tester.pumpWidget(
        buildTestScreen(
          initialMode: LoyaltyScanMode.redeem,
          initialScanResult: testScanRedeemReady,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Confirm & Redeem Reward
      final confirmBtn = find.byKey(const Key('loyalty_confirm_redeem_button'));
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);

      // Advance frames partially -> celebratory success feedback is showing!
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('loyalty_success_feedback_view')), findsOneWidget);
      expect(find.text('Reward Redeemed!'), findsOneWidget);

      // Let animation complete -> returns cleanly to scanner, mode selection unchanged
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_success_feedback_view')), findsNothing);
      expect(find.text('Scan to Redeem Reward'), findsOneWidget);
    });

    testWidgets('Supports starting with initialScanResult', (tester) async {
      await tester.pumpWidget(
        buildTestScreen(initialScanResult: testScanRedeemReady),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')), findsOneWidget);
      expect(find.text('Kabir Verma'), findsOneWidget);
    });

    testWidgets('Renders cleanly in dark theme', (tester) async {
      await tester.pumpWidget(
        buildTestScreen(themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_mode_switch')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.text('Camera Preview'), findsOneWidget);
      expect(find.text('Scan to Add Stamp'), findsOneWidget);
    });

    testWidgets(
        'Detecting a QR code shows in-flight resolving indicator on viewfinder (Task 3B-1 & 3B-2)',
        (tester) async {
      final completer = Completer<Result<LoyaltyScanResult>>();
      final fakeService = FakeLoyaltyService(
        customScanHandler: (token) => completer.future,
      );

      await tester.pumpWidget(buildTestScreen(loyaltyService: fakeService));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('loyalty_scan_resolving_indicator')),
        findsNothing,
      );

      // Trigger QR detection via MobileScanner onDetect callback
      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      mobileScanner.onDetect?.call(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'stamp_test_token_xyz_123')],
        ),
      );
      await tester.pump();

      // In-flight resolving indicator appears on viewfinder
      expect(
        find.byKey(const Key('loyalty_scan_resolving_indicator')),
        findsOneWidget,
      );
      expect(find.text('Resolving loyalty card...'), findsOneWidget);

      // Floating snackbar also appears
      expect(
        find.byKey(const Key('loyalty_scanned_token_snackbar')),
        findsOneWidget,
      );

      // Complete the resolution
      completer.complete(
        const Result.success(
          LoyaltyScanResult(
            customerId: 'cust-1',
            customerName: 'Smruti Rout',
            stamps: 2,
            totalRequired: 10,
            rewardReady: false,
            action: 'stamp',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // View transitions to result card
      expect(
        find.byKey(const Key('loyalty_stamp_confirmation_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('loyalty_scan_resolving_indicator')),
        findsNothing,
      );
    });

    testWidgets(
        'In-flight resolution dismisses cleanly when switching modes',
        (tester) async {
      final completer = Completer<Result<LoyaltyScanResult>>();
      final fakeService = FakeLoyaltyService(
        customScanHandler: (token) => completer.future,
      );

      await tester.pumpWidget(buildTestScreen(loyaltyService: fakeService));
      await tester.pumpAndSettle();

      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      mobileScanner.onDetect?.call(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'dismiss_token_456')],
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('loyalty_scan_resolving_indicator')),
        findsOneWidget,
      );

      // Switch mode to Redeem resets in-flight resolution
      await tester.tap(find.byKey(const Key('loyalty_mode_redeem')));
      completer.complete(
        const Result.failure('Operation cancelled', statusCode: 499),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('loyalty_scan_resolving_indicator')),
        findsNothing,
      );
      expect(find.text('Scan to Redeem Reward'), findsOneWidget);
    });

    testWidgets(
        'Permission denied error displays brand-styled explanation and open settings button (Task 3B-1)',
        (tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      expect(mobileScanner.errorBuilder, isNotNull);

      // Invoke errorBuilder with permissionDenied
      final errorWidget = mobileScanner.errorBuilder!(
        tester.element(find.byType(MobileScanner)),
        const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        ),
      );

      // Pump error widget inside test scaffold
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 300, height: 300, child: errorWidget),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('loyalty_camera_permission_view')),
        findsOneWidget,
      );
      expect(find.text('Camera Access Needed'), findsOneWidget);
      expect(
        find.byKey(const Key('loyalty_open_settings_button')),
        findsOneWidget,
      );
      expect(find.text('Open Settings'), findsOneWidget);
    });
  });

  group('LoyaltyScannerScreen Scan Resolution Tests (Task 3B-2)', () {
    testWidgets(
        'Successful scan matching Stamp mode displays real customer data in stamp card',
        (tester) async {
      final fakeService = FakeLoyaltyService(
        scanResultToReturn: const Result.success(
          LoyaltyScanResult(
            customerId: 'customer_123',
            customerName: 'Smruti Rout',
            stamps: 4,
            totalRequired: 10,
            rewardReady: false,
            action: 'stamp',
          ),
        ),
      );

      await tester.pumpWidget(buildTestScreen(
        initialMode: LoyaltyScanMode.stamp,
        loyaltyService: fakeService,
      ));
      await tester.pumpAndSettle();

      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      mobileScanner.onDetect?.call(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'real_stamp_token_abc')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_stamp_confirmation_card')), findsOneWidget);
      expect(find.text('Smruti Rout'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.byKey(const Key('loyalty_confirm_stamp_button')), findsOneWidget);
    });

    testWidgets(
        'Successful scan matching Redeem mode displays real customer data in redeem card',
        (tester) async {
      final fakeService = FakeLoyaltyService(
        scanResultToReturn: const Result.success(
          LoyaltyScanResult(
            customerId: 'customer_456',
            customerName: 'Smrutiprakash Rout',
            stamps: 10,
            totalRequired: 10,
            rewardReady: true,
            action: 'redeem',
          ),
        ),
      );

      await tester.pumpWidget(buildTestScreen(
        initialMode: LoyaltyScanMode.redeem,
        loyaltyService: fakeService,
      ));
      await tester.pumpAndSettle();

      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      mobileScanner.onDetect?.call(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'real_redeem_token_def')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')), findsOneWidget);
      expect(find.text('Smrutiprakash Rout'), findsOneWidget);
      expect(find.text('REWARD READY!'), findsOneWidget);
      expect(find.byKey(const Key('loyalty_confirm_redeem_button')), findsOneWidget);
    });

    testWidgets(
        'Successful scan with mode mismatch displays mismatch error and NEVER displays result card (PRD A-19)',
        (tester) async {
      final fakeService = FakeLoyaltyService(
        scanResultToReturn: const Result.success(
          LoyaltyScanResult(
            customerId: 'customer_789',
            customerName: 'Aarav Mehta',
            stamps: 10,
            totalRequired: 10,
            rewardReady: true,
            action: 'redeem',
          ),
        ),
      );

      await tester.pumpWidget(buildTestScreen(
        initialMode: LoyaltyScanMode.stamp,
        loyaltyService: fakeService,
      ));
      await tester.pumpAndSettle();

      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      mobileScanner.onDetect?.call(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'mismatched_redeem_token')],
        ),
      );
      await tester.pumpAndSettle();

      // Mismatch error is displayed
      expect(find.byKey(const Key('loyalty_mismatch_error_view')), findsOneWidget);
      expect(find.text('Redeem Code Scanned'), findsOneWidget);
      expect(find.text('This code is for redeeming a reward, not adding a stamp.'), findsOneWidget);

      // Result card is NEVER displayed!
      expect(find.byKey(const Key('loyalty_result_card_view')), findsNothing);
      expect(find.byKey(const Key('loyalty_stamp_confirmation_card')), findsNothing);
      expect(find.byKey(const Key('loyalty_redeem_confirmation_card')), findsNothing);
    });

    testWidgets(
        '404 scan displays token-not-found error state with Back to Scanner button',
        (tester) async {
      final fakeService = FakeLoyaltyService(
        scanResultToReturn: const Result.failure(
          "This QR code doesn't match any customer. Ask the customer to pull up their loyalty card in the customer app.",
          statusCode: 404,
          errorCode: 'TOKEN_NOT_FOUND',
        ),
      );

      await tester.pumpWidget(buildTestScreen(
        initialMode: LoyaltyScanMode.stamp,
        loyaltyService: fakeService,
      ));
      await tester.pumpAndSettle();

      final mobileScanner =
          tester.widget<MobileScanner>(find.byType(MobileScanner));
      mobileScanner.onDetect?.call(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'random_garbage_qr_123')],
        ),
      );
      await tester.pumpAndSettle();

      // Error view is displayed with 404 details
      expect(find.byKey(const Key('loyalty_scan_error_card')), findsOneWidget);
      expect(find.text('404 NOT FOUND'), findsOneWidget);
      expect(find.text('QR Code Not Found'), findsOneWidget);
      expect(
        find.text("This QR code doesn't match any customer. Ask the customer to pull up their loyalty card in the customer app."),
        findsOneWidget,
      );

      // Tapping "Back to Scanner" returns to camera view
      final dismissBtn = find.byKey(const Key('loyalty_error_dismiss_button'));
      await tester.tap(dismissBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_scan_error_card')), findsNothing);
    });

    testWidgets(
        'Confirm Stamp calls addStamp, triggers celebratory feedback, and returns to scanner (Task 3B-3)',
        (tester) async {
      final fakeService = FakeLoyaltyService(
        stampResultToReturn: const Result.success(
          LoyaltyScanResult(
            customerId: 'cust-1',
            customerName: 'Smruti Rout',
            stamps: 3,
            totalRequired: 10,
            rewardReady: false,
            action: 'stamp',
          ),
        ),
      );

      await tester.pumpWidget(buildTestScreen(
        initialScanResult: const LoyaltyScanResult(
          customerId: 'cust-1',
          customerName: 'Smruti Rout',
          stamps: 2,
          totalRequired: 10,
          rewardReady: false,
          action: 'stamp',
        ),
        loyaltyService: fakeService,
      ));
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('loyalty_confirm_stamp_button'));
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pump(); // Start async call

      // Verify service was called
      expect(fakeService.lastStampedCustomerId, 'cust-1');

      // Success feedback appears
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('loyalty_success_view')), findsOneWidget);
      expect(find.text('Stamp Added!'), findsOneWidget);

      // Animation finishes (<600ms) and returns cleanly to scanner
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_success_view')), findsNothing);
    });

    testWidgets(
        'Confirm Redeem calls redeemReward, triggers celebratory feedback, and resets card (Task 3B-3)',
        (tester) async {
      final fakeService = FakeLoyaltyService(
        redeemResultToReturn: const Result.success(
          LoyaltyScanResult(
            customerId: 'cust-2',
            customerName: 'Smrutiprakash Rout',
            stamps: 0,
            totalRequired: 10,
            rewardReady: false,
            action: 'redeem',
          ),
        ),
      );

      await tester.pumpWidget(buildTestScreen(
        initialMode: LoyaltyScanMode.redeem,
        initialScanResult: const LoyaltyScanResult(
          customerId: 'cust-2',
          customerName: 'Smrutiprakash Rout',
          stamps: 10,
          totalRequired: 10,
          rewardReady: true,
          action: 'redeem',
        ),
        loyaltyService: fakeService,
      ));
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('loyalty_confirm_redeem_button'));
      expect(confirmBtn, findsOneWidget);

      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pump();

      // Verify service was called
      expect(fakeService.lastRedeemedCustomerId, 'cust-2');

      // Success feedback appears
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('loyalty_success_view')), findsOneWidget);
      expect(find.text('Reward Redeemed!'), findsOneWidget);

      // Returns cleanly to scanner
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('loyalty_scanner_placeholder')), findsOneWidget);
      expect(find.byKey(const Key('loyalty_success_view')), findsNothing);
    });

    testWidgets(
        'Confirm Stamp 409 conflict displays error state and NEVER shows success feedback (Task 3B-3)',
        (tester) async {
      final fakeService = FakeLoyaltyService(
        stampResultToReturn: const Result.failure(
          "This customer's reward is ready to redeem — stamp it after they redeem, not before.",
          statusCode: 409,
          errorCode: 'REWARD_ALREADY_READY',
        ),
      );

      await tester.pumpWidget(buildTestScreen(
        initialScanResult: const LoyaltyScanResult(
          customerId: 'cust-full',
          customerName: 'Smruti Rout',
          stamps: 10,
          totalRequired: 10,
          rewardReady: true,
          action: 'stamp',
        ),
        loyaltyService: fakeService,
      ));
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('loyalty_confirm_stamp_button'));
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Success view must NEVER be shown
      expect(find.byKey(const Key('loyalty_success_view')), findsNothing);
      expect(find.text('Stamp Added!'), findsNothing);

      // Error view is displayed with 409 conflict message
      expect(find.byKey(const Key('loyalty_scan_error_card')), findsOneWidget);
      expect(find.text('Stamp Conflict'), findsOneWidget);
      expect(
        find.text("This customer's reward is ready to redeem — stamp it after they redeem, not before."),
        findsOneWidget,
      );
    });

    testWidgets(
        'Confirm Redeem 409 conflict displays error state and NEVER shows success feedback (Task 3B-3)',
        (tester) async {
      final fakeService = FakeLoyaltyService(
        redeemResultToReturn: const Result.failure(
          "This customer's card isn't full yet.",
          statusCode: 409,
          errorCode: 'REWARD_NOT_READY',
        ),
      );

      await tester.pumpWidget(buildTestScreen(
        initialMode: LoyaltyScanMode.redeem,
        initialScanResult: const LoyaltyScanResult(
          customerId: 'cust-not-full',
          customerName: 'Smrutiprakash Rout',
          stamps: 10,
          totalRequired: 10,
          rewardReady: true,
          action: 'redeem',
        ),
        loyaltyService: fakeService,
      ));
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('loyalty_confirm_redeem_button'));
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Success view must NEVER be shown
      expect(find.byKey(const Key('loyalty_success_view')), findsNothing);
      expect(find.text('Reward Redeemed!'), findsNothing);

      // Error view is displayed with 409 conflict message
      expect(find.byKey(const Key('loyalty_scan_error_card')), findsOneWidget);
      expect(find.text('Redemption Conflict'), findsOneWidget);
      expect(find.text("This customer's card isn't full yet."), findsOneWidget);
    });

    testWidgets(
        'PRD A-21 Guard: In Redeem mode, Confirm button is disabled when rewardReady is false',
        (tester) async {
      final fakeService = FakeLoyaltyService();

      await tester.pumpWidget(buildTestScreen(
        initialMode: LoyaltyScanMode.redeem,
        initialScanResult: const LoyaltyScanResult(
          customerId: 'cust-incomplete',
          customerName: 'Incomplete Customer',
          stamps: 7,
          totalRequired: 10,
          rewardReady: false,
          action: 'redeem',
        ),
        loyaltyService: fakeService,
      ));
      await tester.pumpAndSettle();

      final confirmBtn = find.byKey(const Key('loyalty_confirm_redeem_button'));
      expect(confirmBtn, findsOneWidget);
      expect(find.text('Reward Not Ready (7/10)'), findsOneWidget);

      // Tap disabled button
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Redeem was NEVER invoked
      expect(fakeService.lastRedeemedCustomerId, isNull);
      expect(find.byKey(const Key('loyalty_success_view')), findsNothing);
    });
  });
}
