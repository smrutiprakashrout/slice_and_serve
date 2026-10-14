import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/loyalty_card.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/brand_card.dart';

/// Top-level result card view displaying the scanned customer loyalty card.
///
/// Implements `PRD.md` §3.4 (A-20, A-21) and `TASKS.md` 3A-3:
/// - Distinct visual hierarchy between routine **Stamp** and celebratory **Redeem**
/// - Stamp card: routine, lower-ceremony, shows progress (X of Y) with visual circular stamps
/// - Redeem card: high-ceremony, celebratory "REWARD READY!" treatment with full 10/10 stamps,
///   cautionary reset disclaimer, and heavier deliberate confirm action
class LoyaltyCardView extends StatelessWidget {
  final LoyaltyScanResult scanResult;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isLoading;

  const LoyaltyCardView({
    super.key,
    required this.scanResult,
    required this.onConfirm,
    required this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (scanResult.isRedeemAction) {
      return RedeemConfirmationCard(
        scanResult: scanResult,
        onConfirm: onConfirm,
        onCancel: onCancel,
        isLoading: isLoading,
      );
    }
    return StampConfirmationCard(
      scanResult: scanResult,
      onConfirm: onConfirm,
      onCancel: onCancel,
      isLoading: isLoading,
    );
  }
}

/// Routine stamp confirmation card with visual circular stamp progress.
class StampConfirmationCard extends StatelessWidget {
  final LoyaltyScanResult scanResult;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isLoading;

  const StampConfirmationCard({
    super.key,
    required this.scanResult,
    required this.onConfirm,
    required this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final nextStampIndex = scanResult.stamps + 1;
    final completesCard = nextStampIndex >= scanResult.totalRequired;

    return BrandCard(
      key: const Key('loyalty_stamp_confirmation_card'),
      radius: BrandCardRadius.large,
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: mode tag & dismiss button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space1 + 1,
                ),
                decoration: BoxDecoration(
                  color: theme.surfaceCreamAlt,
                  borderRadius: AppTokens.borderRadiusPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 14,
                      color: AppTokens.brandInk,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Text(
                      'ADD STAMP',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.brandInk,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('loyalty_card_close_button'),
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: theme.textSecondary,
                ),
                tooltip: 'Dismiss card',
                onPressed: onCancel,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),

          // Customer info header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.surfaceCreamAlt2,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    scanResult.customerName.isNotEmpty
                        ? scanResult.customerName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.brandInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scanResult.customerName,
                      key: const Key('loyalty_customer_name'),
                      style: AppTypography.screenTitle(color: theme.brandInk).copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Customer ID: ${scanResult.customerId}',
                      style: AppTypography.labelCaption(color: theme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),

          Divider(color: theme.divider, height: 1),
          const SizedBox(height: AppTokens.space4),

          // Progress stat header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: AppTokens.space2,
            runSpacing: AppTokens.space2,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Card Progress',
                    style: AppTypography.labelCaption(color: theme.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${scanResult.stamps}',
                        style: AppTypography.statNumber(color: theme.brandInk).copyWith(
                          fontSize: 28,
                        ),
                      ),
                      Text(
                        ' of ${scanResult.totalRequired} stamps',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space2 + 2,
                  vertical: AppTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: completesCard
                      ? theme.brandHighlight.withValues(alpha: 0.28)
                      : theme.surfaceCreamAlt,
                  borderRadius: AppTokens.borderRadiusSmall,
                ),
                child: Text(
                  completesCard ? '🎉 Completes card!' : '+1 stamp pending',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.brandInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),

          // Visual Stamp Grid (10 circular stamps)
          LoyaltyStampGrid(
            stamps: scanResult.stamps,
            totalRequired: scanResult.totalRequired,
            previewNextStamp: true,
          ),
          const SizedBox(height: AppTokens.space6),

          // Primary Confirm Stamp action
          BrandButton(
            key: const Key('loyalty_confirm_stamp_button'),
            text: completesCard
                ? 'Confirm Stamp (Completes Card)'
                : 'Confirm Stamp',
            icon: Icons.check_circle_outline_rounded,
            height: 52.0,
            isLoading: isLoading,
            onPressed: isLoading ? null : onConfirm,
          ),
          const SizedBox(height: AppTokens.space2),

          // Secondary Cancel action
          BrandButton.outlined(
            key: const Key('loyalty_cancel_stamp_button'),
            text: 'Cancel / Rescan',
            height: 48.0,
            isDisabled: isLoading,
            onPressed: isLoading ? null : onCancel,
          ),
        ],
      ),
    );
  }
}

/// Celebratory, deliberate redeem confirmation card.
class RedeemConfirmationCard extends StatelessWidget {
  final LoyaltyScanResult scanResult;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isLoading;

  const RedeemConfirmationCard({
    super.key,
    required this.scanResult,
    required this.onConfirm,
    required this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const Key('loyalty_redeem_confirmation_card'),
      decoration: BoxDecoration(
        color: theme.surfaceCream,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(
          color: theme.brandHighlight,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.brandHighlight.withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top celebration badge & dismiss button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space1 + 1,
                ),
                decoration: BoxDecoration(
                  color: theme.brandHighlight,
                  borderRadius: AppTokens.borderRadiusPill,
                  boxShadow: [
                    BoxShadow(
                      color: theme.brandHighlight.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppTokens.brandInk,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Text(
                      'REWARD READY!',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.brandInk,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('loyalty_card_close_button'),
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: theme.textSecondary,
                ),
                tooltip: 'Dismiss card',
                onPressed: onCancel,
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),

          // Celebratory Avatar / Icon Hero
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.surfaceCreamAlt,
                border: Border.all(
                  color: theme.brandHighlight,
                  width: 2.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.card_giftcard_rounded,
                  size: 38,
                  color: AppTokens.brandInk,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space3),

          // Prominent customer name
          Center(
            child: Column(
              children: [
                Text(
                  scanResult.customerName,
                  key: const Key('loyalty_customer_name'),
                  textAlign: TextAlign.center,
                  style: AppTypography.screenTitle(color: theme.brandInk).copyWith(
                    fontSize: 24,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Customer ID: ${scanResult.customerId}',
                  style: AppTypography.labelCaption(color: theme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),

          // Reward entitlement box
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space4,
              vertical: AppTokens.space3,
            ),
            decoration: BoxDecoration(
              color: theme.surfaceCreamAlt,
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
              border: Border.all(
                color: theme.divider,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppTokens.brandHighlight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    size: 20,
                    color: AppTokens.brandInk,
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1x Free Artisan Pizza',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.brandInk,
                        ),
                      ),
                      Text(
                        'Full 10/10 Stamp Card Reward',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),

          // Visual full stamps grid (all 10 completed)
          LoyaltyStampGrid(
            stamps: scanResult.stamps,
            totalRequired: scanResult.totalRequired,
            isRedeemMode: true,
          ),
          const SizedBox(height: AppTokens.space4),

          // Irreversible action notice
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space3 + 2,
              vertical: AppTokens.space2 + 2,
            ),
            decoration: BoxDecoration(
              color: theme.warningBackground,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
              border: Border.all(
                color: theme.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.warning,
                ),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Text(
                    'Confirming will reset this card back to 0 stamps and mark the reward as claimed. This action cannot be undone.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.brandInk,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space5),

          // Explicit Confirm & Redeem Button (weightier 58dp height)
          // PRD A-21 Guard: Redeem is only enabled when rewardReady == true
          BrandButton(
            key: const Key('loyalty_confirm_redeem_button'),
            text: scanResult.rewardReady
                ? 'Confirm & Redeem Reward'
                : 'Reward Not Ready (${scanResult.stamps}/${scanResult.totalRequired})',
            icon: Icons.redeem_rounded,
            height: 58.0,
            isLoading: isLoading,
            isDisabled: !scanResult.rewardReady,
            onPressed:
                (!scanResult.rewardReady || isLoading) ? null : onConfirm,
          ),
          const SizedBox(height: AppTokens.space2),

          // Cancel / Keep Reward action
          BrandButton.outlined(
            key: const Key('loyalty_cancel_redeem_button'),
            text: 'Keep Reward / Cancel',
            height: 48.0,
            isDisabled: isLoading,
            onPressed: isLoading ? null : onCancel,
          ),
        ],
      ),
    );
  }
}

/// Reusable grid displaying circular stamp progress.
///
/// Implements `polished-flutter-ui` Progress / Loyalty recipe:
/// - Filled stamps: filled with brandHighlight and pizza icon
/// - Pending next stamp: highlighted ring with + icon
/// - Empty stamps: soft muted outline with index number
class LoyaltyStampGrid extends StatelessWidget {
  final int stamps;
  final int totalRequired;
  final bool isRedeemMode;
  final bool previewNextStamp;

  const LoyaltyStampGrid({
    super.key,
    required this.stamps,
    required this.totalRequired,
    this.isRedeemMode = false,
    this.previewNextStamp = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const itemsPerRow = 5;
        const gap = 8.0;
        final itemSize =
            ((availableWidth - (gap * (itemsPerRow - 1))) / itemsPerRow)
                .clamp(36.0, 48.0);

        final firstRow = List.generate(itemsPerRow, (index) => index + 1);
        final secondRow = List.generate(
          (totalRequired - itemsPerRow).clamp(0, itemsPerRow),
          (index) => index + itemsPerRow + 1,
        );

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: firstRow
                  .map((index) =>
                      _buildStampCircle(context, index, itemSize, theme))
                  .toList(),
            ),
            const SizedBox(height: gap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: secondRow
                  .map((index) =>
                      _buildStampCircle(context, index, itemSize, theme))
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStampCircle(
    BuildContext context,
    int index,
    double size,
    AppThemeExtension theme,
  ) {
    final isFilled = index <= stamps;
    final isNext = previewNextStamp && (index == stamps + 1);
    final isMilestone = index == totalRequired;

    if (isFilled) {
      return Container(
        key: Key('stamp_circle_$index'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTokens.brandHighlight,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTokens.brandHighlight.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          (isRedeemMode && isMilestone)
              ? Icons.military_tech_rounded
              : Icons.local_pizza_rounded,
          size: size * 0.52,
          color: AppTokens.brandInk,
        ),
      );
    }

    if (isNext) {
      return Container(
        key: Key('stamp_circle_$index'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.surfaceCreamAlt,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTokens.brandHighlight,
            width: 2.0,
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          size: size * 0.52,
          color: theme.brandInk,
        ),
      );
    }

    return Container(
      key: Key('stamp_circle_$index'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.divider,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '$index',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
