import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Visual style variants for [BrandButton].
enum BrandButtonVariant {
  primary,
  secondary,
  outlined,
  destructive,
}

/// A brand-styled button component adhering to `DESIGN_TOKENS.md`
/// and the `polished-flutter-ui` interaction system.
///
/// Features:
/// - 56dp height (configurable) and full stadium pill radius
/// - 0.97 press-scale spring feedback with light haptic response
/// - Loading state that preserves dimensions without layout shift
/// - Visually distinct disabled state
/// - Primary, secondary, outlined, and destructive visual variants
class BrandButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final BrandButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;

  const BrandButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = BrandButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width = double.infinity,
    this.height = 56.0,
    this.padding,
  });

  const BrandButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width = double.infinity,
    this.height = 56.0,
    this.padding,
  }) : variant = BrandButtonVariant.secondary;

  const BrandButton.outlined({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width = double.infinity,
    this.height = 56.0,
    this.padding,
  }) : variant = BrandButtonVariant.outlined;

  const BrandButton.destructive({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width = double.infinity,
    this.height = 56.0,
    this.padding,
  }) : variant = BrandButtonVariant.destructive;

  @override
  State<BrandButton> createState() => _BrandButtonState();
}

class _BrandButtonState extends State<BrandButton> {
  bool _isPressed = false;

  bool get _isEnabled =>
      !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

  void _handleTapDown(TapDownDetails details) {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appTheme;
    final enabled = _isEnabled;

    Color backgroundColor;
    Color foregroundColor;
    Border? border;

    switch (widget.variant) {
      case BrandButtonVariant.primary:
        backgroundColor = AppTokens.brandHighlight;
        // Dark ink text on yellow reads better than white in both modes
        foregroundColor = AppTokens.brandInk;
        border = null;
      case BrandButtonVariant.secondary:
        backgroundColor = colors.surfaceCreamAlt;
        foregroundColor = colors.brandInk;
        border = null;
      case BrandButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.brandInk;
        border = Border.all(color: colors.divider, width: 1.5);
      case BrandButtonVariant.destructive:
        backgroundColor = colors.error;
        foregroundColor = Colors.white;
        border = null;
    }

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AnimatedScale(
      scale: (_isPressed && enabled && !reduceMotion) ? 0.97 : 1.0,
      duration: reduceMotion ? Duration.zero : AppTokens.motionMicro,
      curve: AppTokens.curveSpring,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: GestureDetector(
          onTapDown: enabled ? _handleTapDown : null,
          onTapUp: enabled ? _handleTapUp : null,
          onTapCancel: enabled ? _handleTapCancel : null,
          onTap: enabled ? widget.onPressed : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppTokens.borderRadiusPill,
              border: border,
            ),
            padding: widget.padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4,
                ),
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: foregroundColor,
                        ),
                        const SizedBox(width: AppTokens.space2),
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: foregroundColor,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
