import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/brand_card.dart';

/// Formats a [DateTime] into a friendly relative string (e.g. "2 min ago", "Yesterday").
String formatRelativeTime(DateTime dateTime, {DateTime? baseTime}) {
  final now = baseTime ?? DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.isNegative || difference.inSeconds < 45) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    final mins = difference.inMinutes;
    return mins == 1 ? '1 min ago' : '$mins min ago';
  } else if (difference.inHours < 24) {
    final hours = difference.inHours;
    return hours == 1 ? '1 hour ago' : '$hours hours ago';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _monthName(dateTime.month);
    return '$day $month';
  }
}

String _monthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[(month - 1).clamp(0, 11)];
}

/// Maps internal order status strings to user-facing display labels.
///
/// Under 4A-5 post-review revision:
/// - "pending" -> "Pending"
/// - "accepted" -> "Preparing" (display-only rename per PRD §3.5)
/// - "completed" -> "Completed"
/// - "rejected" -> "Rejected" (defensive fallback; rejected orders are never displayed in 4A-5)
String displayLabelFor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'Pending';
    case 'accepted':
      return 'Preparing';
    case 'completed':
      return 'Completed';
    case 'rejected':
      return 'Rejected';
    default:
      return status;
  }
}

/// An individual order card displaying fulfillment, table number (when present),
/// items list, customer name, total in Playfair Display, and status accent.
///
/// Implements `PRD.md` §3.5 (A-24, A-25) & `DESIGN_TOKENS.md`.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final DateTime? referenceTime;
  final bool isProcessing;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onComplete,
    this.referenceTime,
    this.isProcessing = false,
  });

  /// Semantic status color helper per DESIGN_TOKENS.md
  Color _statusColor(AppThemeExtension theme) {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return theme.warning;
      case 'accepted':
      case 'completed':
        return theme.success;
      case 'rejected':
        return theme.error;
      default:
        return theme.textSecondary;
    }
  }

  Color _statusBgColor(AppThemeExtension theme) {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return theme.warningBackground;
      case 'accepted':
      case 'completed':
        return theme.successBackground;
      case 'rejected':
        return theme.errorBackground;
      default:
        return theme.surfaceCreamAlt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final statusColor = _statusColor(theme);
    final statusBg = _statusBgColor(theme);

    return BrandCard(
      key: Key('order_card_${order.id}'),
      onTap: onTap,
      radius: BrandCardRadius.large,
      surface: BrandCardSurface.base,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left status accent stripe (subtle indicator)
              Container(
                width: 4.5,
                decoration: BoxDecoration(
                  color: statusColor,
                ),
              ),

              // Main card body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Fulfillment + Table number + Status badge
                      _buildHeaderRow(context, theme, statusColor, statusBg),
                      const SizedBox(height: AppTokens.space3),

                      // Order ID & Relative Timestamp
                      _buildMetaRow(theme),
                      const SizedBox(height: AppTokens.space2),

                      // Customer Name
                      Text(
                        order.customerName,
                        key: Key('order_customer_${order.id}'),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.brandInk,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space3),

                      // Items list (readable with max-visible pattern)
                      _buildItemsList(theme),
                      const SizedBox(height: AppTokens.space3),

                      // Hairline divider
                      Container(
                        height: 1,
                        color: theme.divider,
                      ),
                      const SizedBox(height: AppTokens.space3),

                      // Bottom Row: Item count & Total in Playfair Display
                      _buildBottomRow(theme),

                      // Action buttons: Pending (Reject & Accept), Accepted (Complete), Terminal (absent)
                      if (order.isPending || order.isAccepted) ...[
                        const SizedBox(height: AppTokens.space3),
                        _buildActionButtons(context, theme),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Row: Fulfillment badge, optional table number, and status badge
  Widget _buildHeaderRow(
    BuildContext context,
    AppThemeExtension theme,
    Color statusColor,
    Color statusBg,
  ) {
    final isDineIn = order.isDineIn;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppTokens.space2,
      runSpacing: AppTokens.space2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fulfillment Tag (Dine-in / Pickup)
            Container(
              key: Key('order_fulfillment_${order.id}'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space2 + 2,
                vertical: AppTokens.space1,
              ),
              decoration: BoxDecoration(
                color: theme.surfaceCreamAlt2,
                borderRadius: AppTokens.borderRadiusSmall,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDineIn
                        ? Icons.restaurant_rounded
                        : Icons.shopping_bag_outlined,
                    size: 13,
                    color: theme.textSecondary,
                  ),
                  const SizedBox(width: AppTokens.space1),
                  Text(
                    isDineIn ? 'Dine-in' : 'Pickup',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            // CRITICAL (PRD A-25): Table number badge ONLY when dine-in AND tableNumber != null
            // When dine-in with no table number (e.g. ORD-102), this is gracefully absent.
            if (isDineIn && order.tableNumber != null && order.tableNumber!.isNotEmpty) ...[
              const SizedBox(width: AppTokens.space2),
              Container(
                key: Key('order_table_${order.id}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space2 + 2,
                  vertical: AppTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: theme.surfaceCreamAlt,
                  borderRadius: AppTokens.borderRadiusSmall,
                  border: Border.all(
                    color: theme.divider,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.table_restaurant_rounded,
                      size: 13,
                      color: theme.brandInk,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Text(
                      order.tableNumber!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.brandInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),

        // Status Badge with 15% opacity background & full-strength color
        Container(
          key: Key('order_status_badge_${order.id}'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space2 + 3,
            vertical: AppTokens.space1,
          ),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: AppTokens.borderRadiusSmall,
            border: Border.all(
              color: statusColor.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _statusIcon(order.status),
                size: 11,
                color: statusColor,
              ),
              const SizedBox(width: AppTokens.space1),
              Text(
                _statusLabel(order.status),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Order identifier & relative time row
  Widget _buildMetaRow(AppThemeExtension theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '#${order.id}',
          key: Key('order_id_${order.id}'),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: theme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 12,
              color: theme.textSecondary,
            ),
            const SizedBox(width: AppTokens.space1),
            Text(
              formatRelativeTime(order.placedAt, baseTime: referenceTime),
              key: Key('order_time_${order.id}'),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Line items with quantities
  Widget _buildItemsList(AppThemeExtension theme) {
    const maxVisibleItems = 3;
    final visibleItems = order.items.take(maxVisibleItems).toList();
    final remainingCount = order.items.length - maxVisibleItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in visibleItems)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: Row(
              children: [
                // Quantity pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: theme.surfaceCreamAlt,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${item.quantity}x',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.brandInk,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                // Item Name
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.brandInk,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space2),
                // Item Line Price
                Text(
                  '₹${item.lineTotal.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '+ $remainingCount more ${remainingCount == 1 ? 'item' : 'items'}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: theme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  /// Bottom row: Total items count and total price in Playfair Display
  Widget _buildBottomRow(AppThemeExtension theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${order.totalItemCount} ${order.totalItemCount == 1 ? 'item' : 'items'}',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.textSecondary,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Total ',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
            Text(
              '₹${order.total.toStringAsFixed(0)}',
              key: Key('order_total_${order.id}'),
              style: AppTypography.statNumber(color: theme.brandInk).copyWith(
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'accepted':
        return Icons.soup_kitchen_rounded;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
  String _statusLabel(String status) => displayLabelFor(status);

  /// Action buttons per PRD A-26:
  /// - Pending: Reject (destructive variant) and Accept (primary variant)
  /// - Accepted: Complete (primary variant)
  /// - Completed / Rejected: genuinely absent (terminal states per PROJECT_CONTEXT.md §4)
  Widget _buildActionButtons(BuildContext context, AppThemeExtension theme) {
    if (order.isPending) {
      return Row(
        children: [
          Expanded(
            child: BrandButton.destructive(
              key: Key('order_reject_button_${order.id}'),
              text: 'Reject',
              icon: Icons.close_rounded,
              height: 48.0,
              isDisabled: isProcessing,
              onPressed: isProcessing ? null : onReject,
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: BrandButton(
              key: Key('order_accept_button_${order.id}'),
              text: 'Accept',
              icon: Icons.check_rounded,
              height: 48.0,
              isLoading: isProcessing,
              isDisabled: isProcessing,
              onPressed: isProcessing ? null : onAccept,
            ),
          ),
        ],
      );
    } else if (order.isAccepted) {
      return BrandButton(
        key: Key('order_complete_button_${order.id}'),
        text: 'Complete',
        icon: Icons.done_all_rounded,
        height: 48.0,
        isLoading: isProcessing,
        isDisabled: isProcessing,
        onPressed: isProcessing ? null : onComplete,
      );
    }
    return const SizedBox.shrink();
  }
}

