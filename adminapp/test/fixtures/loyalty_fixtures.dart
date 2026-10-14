import 'package:adminapp/models/loyalty_card.dart';

/// Test fixture loyalty scan results for widget and unit tests.
///
/// Replaces the Stage A `mock_loyalty.dart` file for test purposes.
const testScanStampInProgress = LoyaltyScanResult(
  customerId: 'cust_aarav_001',
  customerName: 'Aarav Mehta',
  stamps: 6,
  totalRequired: 10,
  rewardReady: false,
  action: 'stamp',
);

const testScanStampCompletes = LoyaltyScanResult(
  customerId: 'cust_riya_002',
  customerName: 'Riya Sharma',
  stamps: 9,
  totalRequired: 10,
  rewardReady: false,
  action: 'stamp',
);

const testScanRedeemReady = LoyaltyScanResult(
  customerId: 'cust_kabir_003',
  customerName: 'Kabir Verma',
  stamps: 10,
  totalRequired: 10,
  rewardReady: true,
  action: 'redeem',
);

const testScanMismatchStampOnRedeem = LoyaltyScanResult(
  customerId: 'cust_ananya_004',
  customerName: 'Ananya Patel',
  stamps: 4,
  totalRequired: 10,
  rewardReady: false,
  action: 'stamp',
);

const testScanMismatchRedeemOnStamp = LoyaltyScanResult(
  customerId: 'cust_devansh_005',
  customerName: 'Devansh Joshi',
  stamps: 10,
  totalRequired: 10,
  rewardReady: true,
  action: 'redeem',
);

const testScanModeMismatch = testScanMismatchStampOnRedeem;

// Aliases for backwards compatibility with tests that used mock names
const mockScanStampInProgress = testScanStampInProgress;
const mockScanStampCompletes = testScanStampCompletes;
const mockScanRedeemReady = testScanRedeemReady;
const mockScanMismatchStampOnRedeem = testScanMismatchStampOnRedeem;
const mockScanMismatchRedeemOnStamp = testScanMismatchRedeemOnStamp;
const mockScanModeMismatch = testScanModeMismatch;

const Map<String, LoyaltyScanResult> testLoyaltyScenarios = {
  'stamp_in_progress': testScanStampInProgress,
  'stamp_completes': testScanStampCompletes,
  'redeem_ready': testScanRedeemReady,
  'mismatch_stamp_on_redeem': testScanMismatchStampOnRedeem,
  'mismatch_redeem_on_stamp': testScanMismatchRedeemOnStamp,
};

const mockLoyaltyScenarios = testLoyaltyScenarios;

LoyaltyScanResult getTestScanForMode({
  required String mode,
  bool triggerMismatch = false,
  bool completesCard = false,
}) {
  if (triggerMismatch) {
    return mode == 'redeem'
        ? testScanMismatchStampOnRedeem
        : testScanMismatchRedeemOnStamp;
  }
  if (mode == 'redeem') {
    return testScanRedeemReady;
  }
  return completesCard ? testScanStampCompletes : testScanStampInProgress;
}

LoyaltyScanResult getMockScanForMode({
  required String mode,
  bool triggerMismatch = false,
  bool completesCard = false,
}) =>
    getTestScanForMode(
      mode: mode,
      triggerMismatch: triggerMismatch,
      completesCard: completesCard,
    );
