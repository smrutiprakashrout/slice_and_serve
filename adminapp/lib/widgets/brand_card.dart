import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Configurable corner radii for [BrandCard] based on `DESIGN_TOKENS.md`.
enum BrandCardRadius {
  large(AppTokens.radiusLarge),
  medium(AppTokens.radiusMedium),
  small(AppTokens.radiusSmall);

  final double value;
  const BrandCardRadius(this.value);
}

/// Surface tint options for [BrandCard].
enum BrandCardSurface {
  base,
  alt,
  alt2,
}

/// A brand-styled card shell providing themed surface background,
/// gentle elevation / border, and optional spring press feedback when interactive.
class BrandCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BrandCardRadius radius;
  final BrandCardSurface surface;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool showBorder;

  const BrandCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.radius = BrandCardRadius.large,
    this.surface = BrandCardSurface.base,
    this.padding = const EdgeInsets.all(AppTokens.space4),
    this.margin,
    this.showBorder = true,
  });

  @override
  State<BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<BrandCard> {
  bool _isPressed = false;

  bool get _isInteractive =>
      widget.onTap != null || widget.onLongPress != null;

  void _handleTapDown(TapDownDetails details) {
    if (!_isInteractive) return;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    switch (widget.surface) {
      case BrandCardSurface.base:
        backgroundColor = colors.surfaceCream;
      case BrandCardSurface.alt:
        backgroundColor = colors.surfaceCreamAlt;
      case BrandCardSurface.alt2:
        backgroundColor = colors.surfaceCreamAlt2;
    }

    final borderRadius = BorderRadius.circular(widget.radius.value);

    final card = Container(
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: widget.showBorder
            ? Border.all(color: colors.divider, width: 1.0)
            : null,
        boxShadow: [
          BoxShadow(
            color: colors.brandInk.withValues(
              alpha: isDark ? 0.22 : 0.04,
            ),
            blurRadius: _isPressed ? 3 : 8,
            offset: _isPressed ? const Offset(0, 1) : const Offset(0, 2),
          ),
        ],
      ),
      child: widget.child,
    );

    if (!_isInteractive) {
      return card;
    }

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AnimatedScale(
      scale: (_isPressed && !reduceMotion) ? 0.985 : 1.0,
      duration: reduceMotion ? Duration.zero : AppTokens.motionMicro,
      curve: AppTokens.curveSpring,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress != null
            ? () {
                if (_isPressed) {
                  setState(() => _isPressed = false);
                }
                HapticFeedback.mediumImpact();
                widget.onLongPress!();
              }
            : null,
        behavior: HitTestBehavior.opaque,
        child: card,
      ),
    );
  }
}
