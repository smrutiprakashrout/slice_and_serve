import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adminapp/core/result.dart';
import 'package:adminapp/models/loyalty_card.dart';
import 'package:adminapp/providers/loyalty_provider.dart';
import 'package:adminapp/services/loyalty_service.dart';

class MockLoyaltyService extends LoyaltyService {
  Result<LoyaltyScanResult>? mockResult;
  Result<LoyaltyScanResult>? mockStampResult;
  Result<LoyaltyScanResult>? mockRedeemResult;
  String? lastScannedToken;
  String? lastStampedCustomerId;
  String? lastRedeemedCustomerId;

  MockLoyaltyService({
    this.mockResult,
    this.mockStampResult,
    this.mockRedeemResult,
  });

  @override
  Future<Result<LoyaltyScanResult>> scanToken(String token) async {
    lastScannedToken = token;
    return mockResult ??
        const Result.success(
          LoyaltyScanResult(
            customerId: 'mock-1',
            customerName: 'Test Customer',
            stamps: 5,
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
    return mockStampResult ??
        Result.success(
          (currentResult ??
                  const LoyaltyScanResult(
                    customerId: 'mock-1',
                    customerName: 'Test Customer',
                    stamps: 5,
                    totalRequired: 10,
                    rewardReady: false,
                    action: 'stamp',
                  ))
              .copyWith(stamps: (currentResult?.stamps ?? 5) + 1),
        );
  }

  @override
  Future<Result<LoyaltyScanResult>> redeemReward(
    String customerId, {
    LoyaltyScanResult? currentResult,
  }) async {
    lastRedeemedCustomerId = customerId;
    return mockRedeemResult ??
        Result.success(
          (currentResult ??
                  const LoyaltyScanResult(
                    customerId: 'mock-1',
                    customerName: 'Test Customer',
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
  group('LoyaltyScanNotifier / loyaltyScanProvider Tests (Task 3B-2)', () {
    test('initial state is AsyncData(null)', () {
      final mockService = MockLoyaltyService();
      final container = ProviderContainer(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(loyaltyScanProvider);
      expect(state, const AsyncValue<LoyaltyScanResult?>.data(null));
      expect(state.value, isNull);
    });

    test('scanToken transitions to data on successful resolution', () async {
      final mockService = MockLoyaltyService(
        mockResult: const Result.success(
          LoyaltyScanResult(
            customerId: 'cust-101',
            customerName: 'Aarav Mehta',
            stamps: 6,
            totalRequired: 10,
            rewardReady: false,
            action: 'stamp',
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(loyaltyScanProvider.notifier)
          .scanToken('token_aarav');

      expect(result.isSuccess, isTrue);
      expect(mockService.lastScannedToken, 'token_aarav');

      final state = container.read(loyaltyScanProvider);
      expect(state.hasValue, isTrue);
      expect(state.value?.customerName, 'Aarav Mehta');
      expect(state.value?.stamps, 6);
      expect(state.value?.action, 'stamp');
    });

    test('scanToken transitions to error on failure', () async {
      final mockService = MockLoyaltyService(
        mockResult: const Result.failure(
          "This QR code doesn't match any customer.",
          statusCode: 404,
          errorCode: 'TOKEN_NOT_FOUND',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(loyaltyScanProvider.notifier)
          .scanToken('bad_token');

      expect(result.isFailure, isTrue);
      final failure = result as Failure;
      expect(failure.statusCode, 404);
      expect(failure.errorCode, 'TOKEN_NOT_FOUND');

      final state = container.read(loyaltyScanProvider);
      expect(state.hasError, isTrue);
      expect(
        state.error.toString(),
        contains("This QR code doesn't match any customer."),
      );
    });

    test('clearScan resets state back to AsyncData(null)', () async {
      final mockService = MockLoyaltyService(
        mockResult: const Result.success(
          LoyaltyScanResult(
            customerId: 'cust-102',
            customerName: 'Kabir Verma',
            stamps: 10,
            totalRequired: 10,
            rewardReady: true,
            action: 'redeem',
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(loyaltyScanProvider.notifier)
          .scanToken('token_kabir');
      expect(container.read(loyaltyScanProvider).value, isNotNull);

      // Reset
      container.read(loyaltyScanProvider.notifier).clearScan();
      final state = container.read(loyaltyScanProvider);
      expect(state.value, isNull);
    });
  });

  group('LoyaltyScanNotifier.confirmStamp Tests (Task 3B-3)', () {
    test('confirmStamp succeeds, calls service, and updates state', () async {
      final mockService = MockLoyaltyService(
        mockResult: const Result.success(
          LoyaltyScanResult(
            customerId: 'cust-101',
            customerName: 'Aarav Mehta',
            stamps: 6,
            totalRequired: 10,
            rewardReady: false,
            action: 'stamp',
          ),
        ),
        mockStampResult: const Result.success(
          LoyaltyScanResult(
            customerId: 'cust-101',
            customerName: 'Aarav Mehta',
            stamps: 7,
            totalRequired: 10,
            rewardReady: false,
            action: 'stamp',
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Preload active scan
      await container
          .read(loyaltyScanProvider.notifier)
          .scanToken('token_aarav');

      final result =
          await container.read(loyaltyScanProvider.notifier).confirmStamp();

      expect(result.isSuccess, isTrue);
      expect(mockService.lastStampedCustomerId, 'cust-101');

      final state = container.read(loyaltyScanProvider);
      expect(state.value?.stamps, 7);
      expect(state.value?.customerId, 'cust-101');
    });

    test('confirmStamp fails if no active scan is held and none passed', () async {
      final mockService = MockLoyaltyService();
      final container = ProviderContainer(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(loyaltyScanProvider.notifier).confirmStamp();

      expect(result.isFailure, isTrue);
      final failure = result as Failure<LoyaltyScanResult>;
      expect(failure.errorCode, 'NO_ACTIVE_SCAN');
    });

    test('confirmStamp surfaces service failure without updating state to data', () async {
      final mockService = MockLoyaltyService(
        mockStampResult: const Result.failure(
          "This customer's reward is ready to redeem — stamp it after they redeem, not before.",
          statusCode: 409,
          errorCode: 'REWARD_ALREADY_READY',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      const scanResult = LoyaltyScanResult(
        customerId: 'cust-full',
        customerName: 'Full Card User',
        stamps: 10,
        totalRequired: 10,
        rewardReady: true,
        action: 'stamp',
      );

      final result = await container
          .read(loyaltyScanProvider.notifier)
          .confirmStamp(scanResult);

      expect(result.isFailure, isTrue);
      final failure = result as Failure<LoyaltyScanResult>;
      expect(failure.statusCode, 409);
      expect(failure.errorCode, 'REWARD_ALREADY_READY');
    });
  });

  group('LoyaltyScanNotifier.confirmRedeem Tests (Task 3B-3)', () {
    test('confirmRedeem succeeds when rewardReady is true', () async {
      final mockService = MockLoyaltyService(
        mockRedeemResult: const Result.success(
          LoyaltyScanResult(
            customerId: 'cust-ready',
            customerName: 'Smrutiprakash Rout',
            stamps: 0,
            totalRequired: 10,
            rewardReady: false,
            action: 'redeem',
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      const readyCard = LoyaltyScanResult(
        customerId: 'cust-ready',
        customerName: 'Smrutiprakash Rout',
        stamps: 10,
        totalRequired: 10,
        rewardReady: true,
        action: 'redeem',
      );

      final result = await container
          .read(loyaltyScanProvider.notifier)
          .confirmRedeem(readyCard);

      expect(result.isSuccess, isTrue);
      expect(mockService.lastRedeemedCustomerId, 'cust-ready');

      final state = container.read(loyaltyScanProvider);
      expect(state.value?.stamps, 0);
      expect(state.value?.rewardReady, isFalse);
    });

    test('confirmRedeem enforces PRD A-21 guard when rewardReady is false', () async {
      final mockService = MockLoyaltyService();
      final container = ProviderContainer(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      const notReadyCard = LoyaltyScanResult(
        customerId: 'cust-incomplete',
        customerName: 'Incomplete User',
        stamps: 8,
        totalRequired: 10,
        rewardReady: false,
        action: 'redeem',
      );

      final result = await container
          .read(loyaltyScanProvider.notifier)
          .confirmRedeem(notReadyCard);

      expect(result.isFailure, isTrue);
      final failure = result as Failure<LoyaltyScanResult>;
      expect(failure.statusCode, 409);
      expect(failure.errorCode, 'REWARD_NOT_READY');
      expect(failure.errorMessage, contains("isn't full yet"));
      expect(mockService.lastRedeemedCustomerId, isNull);
    });

    test('confirmRedeem fails if no scan result is available', () async {
      final mockService = MockLoyaltyService();
      final container = ProviderContainer(
        overrides: [
          loyaltyServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(loyaltyScanProvider.notifier).confirmRedeem();

      expect(result.isFailure, isTrue);
      final failure = result as Failure<LoyaltyScanResult>;
      expect(failure.errorCode, 'NO_ACTIVE_SCAN');
    });
  });
}
