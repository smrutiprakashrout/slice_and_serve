import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/result.dart';
import '../models/loyalty_card.dart';
import '../services/loyalty_service.dart';
import 'auth_provider.dart';

/// Provider for [LoyaltyService], injected with the shared [ApiClient].
final loyaltyServiceProvider = Provider<LoyaltyService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LoyaltyService(apiClient: apiClient);
});

/// Riverpod AsyncNotifier managing the active loyalty scan state.
///
/// Implements `ARCHITECTURE.md` §3, §4, §5.3, `CODING_STANDARDS.md` §2, and `TASKS.md` Phase 3B (3B-2).
/// - Initial state is `const AsyncValue.data(null)` (idle, ready for scan).
/// - [scanToken] resolves a scanned QR token to its customer and loyalty card data.
/// - Exposes [clearScan] to reset state back to ready for next scan.
class LoyaltyScanNotifier extends AsyncNotifier<LoyaltyScanResult?> {
  @override
  FutureOr<LoyaltyScanResult?> build() {
    return null;
  }

  /// Resolves [token] via [LoyaltyService.scanToken].
  ///
  /// Updates [state] to [AsyncLoading] while resolving.
  /// Sets [state] to [AsyncData] on success or [AsyncError] on failure,
  /// and returns the underlying [Result] to the caller.
  Future<Result<LoyaltyScanResult>> scanToken(String token) async {
    state = const AsyncValue.loading();
    final loyaltyService = ref.read(loyaltyServiceProvider);
    final result = await loyaltyService.scanToken(token);

    return result.when(
      success: (data) {
        state = AsyncValue.data(data);
        return Result.success(data);
      },
      failure: (message, statusCode, errorCode) {
        state = AsyncValue.error(Exception(message), StackTrace.current);
        return Result.failure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      },
    );
  }

  /// Confirms adding a stamp to the customer's loyalty card.
  ///
  /// Uses [scanResult] if provided, otherwise the active [state.value].
  /// Calls [LoyaltyService.addStamp].
  /// On success, updates [state] to [AsyncValue.data] with the updated card state.
  /// Returns the underlying [Result] to the caller.
  Future<Result<LoyaltyScanResult>> confirmStamp([
    LoyaltyScanResult? scanResult,
  ]) async {
    final current = scanResult ?? state.value;
    if (current == null || current.customerId.trim().isEmpty) {
      return const Result.failure(
        'No active loyalty scan to confirm.',
        statusCode: 400,
        errorCode: 'NO_ACTIVE_SCAN',
      );
    }

    final loyaltyService = ref.read(loyaltyServiceProvider);
    final result = await loyaltyService.addStamp(
      current.customerId,
      currentResult: current,
    );

    return result.when(
      success: (updated) {
        state = AsyncValue.data(updated);
        return Result.success(updated);
      },
      failure: (message, statusCode, errorCode) {
        return Result.failure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      },
    );
  }

  /// Confirms redeeming the reward for the customer's full loyalty card.
  ///
  /// PRD A-21 Guard: Verifies that [rewardReady] is true before initiating request.
  /// Uses [scanResult] if provided, otherwise the active [state.value].
  /// Calls [LoyaltyService.redeemReward].
  /// On success, updates [state] to [AsyncValue.data] with the reset card state.
  /// Returns the underlying [Result] to the caller.
  Future<Result<LoyaltyScanResult>> confirmRedeem([
    LoyaltyScanResult? scanResult,
  ]) async {
    final current = scanResult ?? state.value;
    if (current == null || current.customerId.trim().isEmpty) {
      return const Result.failure(
        'No active loyalty scan to redeem.',
        statusCode: 400,
        errorCode: 'NO_ACTIVE_SCAN',
      );
    }

    // PRD A-21 guard: Redeem is only ever offered when rewardReady == true
    if (!current.rewardReady) {
      return const Result.failure(
        "This customer's card isn't full yet. Cannot redeem reward.",
        statusCode: 409,
        errorCode: 'REWARD_NOT_READY',
      );
    }

    final loyaltyService = ref.read(loyaltyServiceProvider);
    final result = await loyaltyService.redeemReward(
      current.customerId,
      currentResult: current,
    );

    return result.when(
      success: (updated) {
        state = AsyncValue.data(updated);
        return Result.success(updated);
      },
      failure: (message, statusCode, errorCode) {
        return Result.failure(
          message,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      },
    );
  }

  /// Clears the active scan result and returns to idle scanner state.
  void clearScan() {
    state = const AsyncValue.data(null);
  }
}

/// Provider exposing the current [LoyaltyScanResult] as an [AsyncValue].
final loyaltyScanProvider =
    AsyncNotifierProvider<LoyaltyScanNotifier, LoyaltyScanResult?>(
  LoyaltyScanNotifier.new,
);
