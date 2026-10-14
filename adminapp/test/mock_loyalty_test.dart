import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/models/loyalty_card.dart';
import 'fixtures/loyalty_fixtures.dart';

void main() {
  group('LoyaltyScanResult Model Tests (Task 3A-1)', () {
    test('instantiates with expected fields per ARCHITECTURE.md §3', () {
      const scan = LoyaltyScanResult(
        customerId: 'cust_123',
        customerName: 'Test Customer',
        stamps: 7,
        totalRequired: 10,
        rewardReady: false,
        action: 'stamp',
      );

      expect(scan.customerId, 'cust_123');
      expect(scan.customerName, 'Test Customer');
      expect(scan.stamps, 7);
      expect(scan.totalRequired, 10);
      expect(scan.rewardReady, isFalse);
      expect(scan.action, 'stamp');
      expect(scan.isStampAction, isTrue);
      expect(scan.isRedeemAction, isFalse);
      expect(scan.isFull, isFalse);
      expect(scan.willCompleteCard, isFalse);
      expect(scan.remainingStamps, 3);
      expect(scan.progress, closeTo(0.7, 0.001));
    });

    test('default totalRequired is 10', () {
      const scan = LoyaltyScanResult(
        customerId: 'cust_def',
        customerName: 'Default User',
        stamps: 3,
        rewardReady: false,
        action: 'stamp',
      );

      expect(scan.totalRequired, 10);
    });

    test('willCompleteCard and isFull calculations work accurately', () {
      const scanNine = LoyaltyScanResult(
        customerId: 'c9',
        customerName: 'Nine',
        stamps: 9,
        totalRequired: 10,
        rewardReady: false,
        action: 'stamp',
      );
      expect(scanNine.willCompleteCard, isTrue);
      expect(scanNine.isFull, isFalse);

      const scanTen = LoyaltyScanResult(
        customerId: 'c10',
        customerName: 'Ten',
        stamps: 10,
        totalRequired: 10,
        rewardReady: true,
        action: 'redeem',
      );
      expect(scanTen.isFull, isTrue);
      expect(scanTen.remainingStamps, 0);
      expect(scanTen.progress, 1.0);
    });

    test('copyWith properly copies and updates fields', () {
      const scan = LoyaltyScanResult(
        customerId: 'cust_1',
        customerName: 'Original',
        stamps: 5,
        totalRequired: 10,
        rewardReady: false,
        action: 'stamp',
      );

      final updated = scan.copyWith(
        stamps: 6,
        rewardReady: true,
        action: 'redeem',
      );

      expect(updated.customerId, 'cust_1');
      expect(updated.customerName, 'Original');
      expect(updated.stamps, 6);
      expect(updated.rewardReady, isTrue);
      expect(updated.action, 'redeem');
    });

    test('equality and hashCode work as value objects', () {
      const scanA = LoyaltyScanResult(
        customerId: 'c1',
        customerName: 'Name',
        stamps: 5,
        totalRequired: 10,
        rewardReady: false,
        action: 'stamp',
      );
      const scanB = LoyaltyScanResult(
        customerId: 'c1',
        customerName: 'Name',
        stamps: 5,
        totalRequired: 10,
        rewardReady: false,
        action: 'stamp',
      );
      const scanDiff = LoyaltyScanResult(
        customerId: 'c2',
        customerName: 'Name',
        stamps: 5,
        totalRequired: 10,
        rewardReady: false,
        action: 'stamp',
      );

      expect(scanA, equals(scanB));
      expect(scanA.hashCode, equals(scanB.hashCode));
      expect(scanA, isNot(equals(scanDiff)));
    });
  });

  group('Mock Loyalty Scenarios Tests (Task 3A-1)', () {
    test('mockScanStampInProgress represents standard stamp card in progress', () {
      expect(mockScanStampInProgress.customerName, 'Aarav Mehta');
      expect(mockScanStampInProgress.stamps, 6);
      expect(mockScanStampInProgress.totalRequired, 10);
      expect(mockScanStampInProgress.rewardReady, isFalse);
      expect(mockScanStampInProgress.action, 'stamp');
      expect(mockScanStampInProgress.isStampAction, isTrue);
      expect(mockScanStampInProgress.isFull, isFalse);
    });

    test('mockScanStampCompletes represents scan that completes the card', () {
      expect(mockScanStampCompletes.customerName, 'Riya Sharma');
      expect(mockScanStampCompletes.stamps, 9);
      expect(mockScanStampCompletes.totalRequired, 10);
      expect(mockScanStampCompletes.rewardReady, isFalse);
      expect(mockScanStampCompletes.action, 'stamp');
      expect(mockScanStampCompletes.willCompleteCard, isTrue);
    });

    test('mockScanRedeemReady represents redeem scan ready for reward', () {
      expect(mockScanRedeemReady.customerName, 'Kabir Verma');
      expect(mockScanRedeemReady.stamps, 10);
      expect(mockScanRedeemReady.totalRequired, 10);
      expect(mockScanRedeemReady.rewardReady, isTrue);
      expect(mockScanRedeemReady.action, 'redeem');
      expect(mockScanRedeemReady.isRedeemAction, isTrue);
      expect(mockScanRedeemReady.isFull, isTrue);
    });

    test('mode mismatch scenarios provide stamp-on-redeem and redeem-on-stamp tokens', () {
      expect(mockScanMismatchStampOnRedeem.action, 'stamp');
      expect(mockScanMismatchRedeemOnStamp.action, 'redeem');
      expect(mockScanModeMismatch, equals(mockScanMismatchStampOnRedeem));
    });

    test('mockLoyaltyScenarios map contains all required scenarios', () {
      expect(mockLoyaltyScenarios.containsKey('stamp_in_progress'), isTrue);
      expect(mockLoyaltyScenarios.containsKey('stamp_completes'), isTrue);
      expect(mockLoyaltyScenarios.containsKey('redeem_ready'), isTrue);
      expect(mockLoyaltyScenarios.containsKey('mismatch_stamp_on_redeem'), isTrue);
      expect(mockLoyaltyScenarios.containsKey('mismatch_redeem_on_stamp'), isTrue);
    });

    test('getMockScanForMode helper correctly resolves scenarios', () {
      expect(getMockScanForMode(mode: 'stamp'), equals(mockScanStampInProgress));
      expect(
        getMockScanForMode(mode: 'stamp', completesCard: true),
        equals(mockScanStampCompletes),
      );
      expect(getMockScanForMode(mode: 'redeem'), equals(mockScanRedeemReady));
      expect(
        getMockScanForMode(mode: 'redeem', triggerMismatch: true),
        equals(mockScanMismatchStampOnRedeem),
      );
      expect(
        getMockScanForMode(mode: 'stamp', triggerMismatch: true),
        equals(mockScanMismatchRedeemOnStamp),
      );
    });
  });
}
