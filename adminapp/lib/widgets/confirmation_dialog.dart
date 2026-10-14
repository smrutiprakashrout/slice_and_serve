import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'brand_button.dart';

/// A brand-styled confirmation modal dialog conforming to `DESIGN_TOKENS.md`
/// and the `polished-flutter-ui` interaction design.
///
/// Designed to be reused across menu item deletion (Phase 2A),
/// order rejection (Phase 4A), and general destructive or standard actions.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  /// Displays the confirmation dialog and returns a [Future<bool>]
  /// representing the user's decision (`true` for confirmed, `false` for dismissed or cancelled).
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;

    final headerIcon = icon ??
        (isDestructive
            ? Icons.warning_amber_rounded
            : Icons.help_outline_rounded);

    final iconColor = isDestructive ? colors.error : colors.brandInk;
    final iconBgColor = isDestructive
        ? colors.errorBackground
        : colors.brandHighlight.withValues(alpha: 0.25);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space6,
        vertical: AppTokens.space6,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTokens.space6),
        decoration: BoxDecoration(
          color: colors.surfaceCream,
          borderRadius: AppTokens.borderRadiusLarge,
          border: Border.all(color: colors.divider, width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header icon badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                headerIcon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: AppTokens.space4),

            // Dialog Title
            Text(
              title,
              style: AppTypography.screenTitle(color: colors.brandInk).copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space2),

            // Dialog Message
            Text(
              message,
              style: AppTypography.body(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space6),

            // Actions row: Cancel & Confirm
            Row(
              children: [
                Expanded(
                  child: BrandButton.outlined(
                    text: cancelLabel,
                    height: 48.0,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: isDestructive
                      ? BrandButton.destructive(
                          text: confirmLabel,
                          height: 48.0,
                          onPressed: () => Navigator.of(context).pop(true),
                        )
                      : BrandButton(
                          text: confirmLabel,
                          height: 48.0,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
