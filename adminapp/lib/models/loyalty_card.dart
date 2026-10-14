import 'package:flutter/foundation.dart';

/// Immutable model representing the result of scanning a customer's loyalty QR code.
///
/// Matches `ARCHITECTURE.md` §3 specification:
/// - [customerId]: Unique identifier for the customer
/// - [customerName]: Customer's display name
/// - [stamps]: Current number of collected stamps (e.g. 0 to 10)
/// - [totalRequired]: Total stamps needed for reward (default 10)
/// - [rewardReady]: Whether the customer is eligible to redeem a reward
/// - [action]: Action type this scan token is valid for ("stamp" | "redeem")
@immutable
class LoyaltyScanResult {
  final String customerId;
  final String customerName;
  final int stamps;
  final int totalRequired;
  final bool rewardReady;
  final String action; // "stamp" | "redeem"

  const LoyaltyScanResult({
    required this.customerId,
    required this.customerName,
    required this.stamps,
    this.totalRequired = 10,
    required this.rewardReady,
    required this.action,
  });

  /// Factory constructor deserializing API response from `GET /api/loyalty/scan/:token`.
  ///
  /// Supports both nested envelope (`customer.name`, `card.stamps`) and flat shapes:
  /// ```json
  /// {
  ///   "customer": { "name": "Smruti Rout" },
  ///   "card": { "stamps": 2, "totalRequired": 10, "rewardReady": false },
  ///   "action": "stamp"
  /// }
  /// ```
  factory LoyaltyScanResult.fromJson(Map<String, dynamic> json) {
    final customerObj = json['customer'] as Map<String, dynamic>?;
    final cardObj = json['card'] as Map<String, dynamic>?;

    final customerId = (customerObj?['id'] ??
            customerObj?['_id'] ??
            json['customerId'] ??
            json['id'] ??
            '')
        .toString();

    final customerName = (customerObj?['name'] ??
            json['customerName'] ??
            json['name'] ??
            'Customer')
        .toString();

    final stamps = (cardObj?['stamps'] as num?)?.toInt() ??
        (json['stamps'] as num?)?.toInt() ??
        0;
    final totalRequired = (cardObj?['totalRequired'] as num?)?.toInt() ??
        (json['totalRequired'] as num?)?.toInt() ??
        10;
    final rewardReady = cardObj?['rewardReady'] as bool? ??
        json['rewardReady'] as bool? ??
        false;
    final action = (json['action'] as String?)?.toLowerCase() ?? 'stamp';

    return LoyaltyScanResult(
      customerId: customerId,
      customerName: customerName,
      stamps: stamps,
      totalRequired: totalRequired,
      rewardReady: rewardReady,
      action: action,
    );
  }

  /// Serializes this instance to JSON.
  Map<String, dynamic> toJson() => {
        'customer': {
          'name': customerName,
          if (customerId.isNotEmpty) 'id': customerId,
        },
        'card': {
          'stamps': stamps,
          'totalRequired': totalRequired,
          'rewardReady': rewardReady,
        },
        'action': action,
      };

  /// True if this scan result represents an "Add Stamp" action.
  bool get isStampAction => action == 'stamp';

  /// True if this scan result represents a "Redeem" action.
  bool get isRedeemAction => action == 'redeem';

  /// True if customer has reached or exceeded the required stamp count.
  bool get isFull => stamps >= totalRequired;

  /// True if customer is exactly one stamp away from completing the card.
  bool get willCompleteCard => stamps + 1 >= totalRequired;

  /// Remaining stamps needed to complete the card.
  int get remainingStamps => (totalRequired - stamps).clamp(0, totalRequired);

  /// Progress ratio from 0.0 to 1.0.
  double get progress =>
      totalRequired > 0 ? (stamps / totalRequired).clamp(0.0, 1.0) : 0.0;

  LoyaltyScanResult copyWith({
    String? customerId,
    String? customerName,
    int? stamps,
    int? totalRequired,
    bool? rewardReady,
    String? action,
  }) {
    return LoyaltyScanResult(
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      stamps: stamps ?? this.stamps,
      totalRequired: totalRequired ?? this.totalRequired,
      rewardReady: rewardReady ?? this.rewardReady,
      action: action ?? this.action,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoyaltyScanResult &&
          runtimeType == other.runtimeType &&
          customerId == other.customerId &&
          customerName == other.customerName &&
          stamps == other.stamps &&
          totalRequired == other.totalRequired &&
          rewardReady == other.rewardReady &&
          action == other.action;

  @override
  int get hashCode => Object.hash(
        customerId,
        customerName,
        stamps,
        totalRequired,
        rewardReady,
        action,
      );

  @override
  String toString() =>
      'LoyaltyScanResult(customerId: $customerId, customerName: $customerName, stamps: $stamps/$totalRequired, rewardReady: $rewardReady, action: $action)';
}

/// Type alias for compatibility if referenced as LoyaltyCard.
typedef LoyaltyCard = LoyaltyScanResult;
