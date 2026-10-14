import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/result.dart';
import '../models/loyalty_card.dart';

/// Service responsible for communicating with `/api/loyalty` endpoints.
///
/// Implements `ARCHITECTURE.md` §4 (`GET /api/loyalty/scan/:token`),
/// `PRD.md` §3.4 (A-18, A-19, A-20), `CODING_STANDARDS.md` §1 (`Result<T>`),
/// and `TASKS.md` Phase 3B (3B-2).
class LoyaltyService {
  final ApiClient _apiClient;

  LoyaltyService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Resolves a scanned QR token to its customer and loyalty card data.
  ///
  /// Calls `GET /api/loyalty/scan/:token`.
  /// On success (200), returns [Result.success] with [LoyaltyScanResult].
  /// On 404 (token does not resolve to any customer), returns [Result.failure]
  /// with a specific message distinguishing it from general network errors:
  /// `"This QR code doesn't match any customer."`
  /// On other errors (e.g. timeout, 500, network loss), returns [Result.failure].
  Future<Result<LoyaltyScanResult>> scanToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return const Result.failure(
        'Invalid token: scanned string is empty.',
        statusCode: 400,
        errorCode: 'INVALID_TOKEN',
      );
    }

    try {
      final encodedToken = Uri.encodeComponent(trimmed);
      final response =
          await _apiClient.dio.get<dynamic>('/api/loyalty/scan/$encodedToken');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final result = LoyaltyScanResult.fromJson(data);
        return Result.success(result);
      }

      return const Result.failure(
        'Invalid response format received from loyalty server.',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        String notFoundMessage = "This QR code doesn't match any customer.";
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          final errorObj = responseData['error'];
          if (errorObj is Map<String, dynamic> &&
              errorObj['message'] is String &&
              (errorObj['message'] as String).isNotEmpty) {
            notFoundMessage = errorObj['message'] as String;
          } else if (responseData['message'] is String) {
            notFoundMessage = responseData['message'] as String;
          }
        }
        return Result.failure(
          notFoundMessage,
          statusCode: 404,
          errorCode: 'TOKEN_NOT_FOUND',
        );
      }
      return ApiClient.failureFromDioException<LoyaltyScanResult>(e);
    } catch (e) {
      return Result.failure(
        'Unexpected error while resolving loyalty token: $e',
      );
    }
  }

  /// Adds a stamp to the customer's loyalty card.
  ///
  /// Calls `POST /api/loyalty/:customerId/stamp`.
  /// On success (200), returns [Result.success] with the updated [LoyaltyScanResult].
  /// On 409 (`REWARD_ALREADY_READY`), returns [Result.failure] with a specific message:
  /// `"This customer's reward is ready to redeem — stamp it after they redeem, not before."`
  /// On 404, returns [Result.failure] indicating customer or loyalty card not found.
  Future<Result<LoyaltyScanResult>> addStamp(
    String customerId, {
    LoyaltyScanResult? currentResult,
  }) async {
    final trimmedId = customerId.trim();
    if (trimmedId.isEmpty) {
      return const Result.failure(
        'Customer ID cannot be empty.',
        statusCode: 400,
        errorCode: 'INVALID_CUSTOMER_ID',
      );
    }

    try {
      final encodedId = Uri.encodeComponent(trimmedId);
      final response = await _apiClient.dio.post<dynamic>(
        '/api/loyalty/$encodedId/stamp',
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final stamps = (data['stamps'] as num?)?.toInt() ??
            (currentResult != null ? currentResult.stamps + 1 : 1);
        final totalRequired = (data['totalRequired'] as num?)?.toInt() ??
            (currentResult?.totalRequired ?? 10);
        final rewardReady = data['rewardReady'] as bool? ??
            (stamps >= totalRequired);

        final updated = currentResult != null
            ? currentResult.copyWith(
                stamps: stamps,
                totalRequired: totalRequired,
                rewardReady: rewardReady,
              )
            : LoyaltyScanResult(
                customerId: trimmedId,
                customerName: (data['customerName'] ?? 'Customer').toString(),
                stamps: stamps,
                totalRequired: totalRequired,
                rewardReady: rewardReady,
                action: 'stamp',
              );
        return Result.success(updated);
      }

      return const Result.failure(
        'Invalid response format received from stamp endpoint.',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        String conflictMessage =
            "This customer's reward is ready to redeem — stamp it after they redeem, not before.";
        String conflictCode = 'REWARD_ALREADY_READY';
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          final errorObj = responseData['error'];
          if (errorObj is Map<String, dynamic>) {
            if (errorObj['message'] is String &&
                (errorObj['message'] as String).isNotEmpty) {
              conflictMessage = errorObj['message'] as String;
            }
            if (errorObj['code'] is String &&
                (errorObj['code'] as String).isNotEmpty) {
              conflictCode = errorObj['code'] as String;
            }
          }
        }
        return Result.failure(
          conflictMessage,
          statusCode: 409,
          errorCode: conflictCode,
        );
      }
      return ApiClient.failureFromDioException<LoyaltyScanResult>(e);
    } catch (e) {
      return Result.failure(
        'Unexpected error while adding stamp: $e',
      );
    }
  }

  /// Redeems the customer's full loyalty card.
  ///
  /// Calls `POST /api/loyalty/:customerId/redeem`.
  /// On success (200), returns [Result.success] with the updated [LoyaltyScanResult] (stamps: 0, rewardReady: false).
  /// On 409 (`REWARD_NOT_READY`), returns [Result.failure] with a specific message:
  /// `"This customer's card isn't full yet."`
  /// On 404, returns [Result.failure] indicating customer or loyalty card not found.
  Future<Result<LoyaltyScanResult>> redeemReward(
    String customerId, {
    LoyaltyScanResult? currentResult,
  }) async {
    final trimmedId = customerId.trim();
    if (trimmedId.isEmpty) {
      return const Result.failure(
        'Customer ID cannot be empty.',
        statusCode: 400,
        errorCode: 'INVALID_CUSTOMER_ID',
      );
    }

    try {
      final encodedId = Uri.encodeComponent(trimmedId);
      final response = await _apiClient.dio.post<dynamic>(
        '/api/loyalty/$encodedId/redeem',
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final stamps = (data['stamps'] as num?)?.toInt() ?? 0;
        final totalRequired = (data['totalRequired'] as num?)?.toInt() ??
            (currentResult?.totalRequired ?? 10);
        final rewardReady = data['rewardReady'] as bool? ?? false;

        final updated = currentResult != null
            ? currentResult.copyWith(
                stamps: stamps,
                totalRequired: totalRequired,
                rewardReady: rewardReady,
              )
            : LoyaltyScanResult(
                customerId: trimmedId,
                customerName: (data['customerName'] ?? 'Customer').toString(),
                stamps: stamps,
                totalRequired: totalRequired,
                rewardReady: rewardReady,
                action: 'redeem',
              );
        return Result.success(updated);
      }

      return const Result.failure(
        'Invalid response format received from redeem endpoint.',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        String conflictMessage = "This customer's card isn't full yet.";
        String conflictCode = 'REWARD_NOT_READY';
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          final errorObj = responseData['error'];
          if (errorObj is Map<String, dynamic>) {
            if (errorObj['message'] is String &&
                (errorObj['message'] as String).isNotEmpty) {
              conflictMessage = errorObj['message'] as String;
            }
            if (errorObj['code'] is String &&
                (errorObj['code'] as String).isNotEmpty) {
              conflictCode = errorObj['code'] as String;
            }
          }
        }
        return Result.failure(
          conflictMessage,
          statusCode: 409,
          errorCode: conflictCode,
        );
      }
      return ApiClient.failureFromDioException<LoyaltyScanResult>(e);
    } catch (e) {
      return Result.failure(
        'Unexpected error while redeeming reward: $e',
      );
    }
  }
}

