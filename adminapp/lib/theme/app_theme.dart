import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for Slice & Serve Admin application.
/// Derived from `DESIGN_TOKENS.md` and `polished-flutter-ui` system.
abstract final class AppTokens {
  // Light color tokens
  static const Color brandInk = Color(0xFF3D1A00);
  static const Color brandHighlight = Color(0xFFFACC15);
  static const Color surfaceCream = Color(0xFFFFF1E3);
  static const Color surfaceCreamAlt = Color(0xFFF0D9B5);
  static const Color surfaceCreamAlt2 = Color(0xFFF0E6DC);
  static const Color background = Color(0xFFFFFAF5);
  static const Color textSecondary = Color(0xA63D1A00); // 65% opacity of #3D1A00
  static const Color divider = Color(0x1F3D1A00); // 12% opacity of #3D1A00
  static const Color success = Color(0xFF4D8B5F);
  static const Color warning = Color(0xFFC9832A);
  static const Color error = Color(0xFFC1503F);

  // Dark color tokens
  static const Color brandInkDark = Color(0xFFFFF1E3);
  static const Color brandHighlightDark = Color(0xFFFACC15);
  static const Color surfaceCreamDark = Color(0xFF2B1810);
  static const Color surfaceCreamAltDark = Color(0xFF33200F);
  static const Color surfaceCreamAlt2Dark = Color(0xFF3A2513);
  static const Color backgroundDark = Color(0xFF1A0F08);
  static const Color textSecondaryDark = Color(0xA6FFF1E3); // 65% opacity of #FFF1E3
  static const Color dividerDark = Color(0x1FFFF1E3); // 12% opacity of #FFF1E3
  static const Color successDark = Color(0xFF62A877); // +8-10% lightness
  static const Color warningDark = Color(0xFFDE9A42); // +8-10% lightness
  static const Color errorDark = Color(0xFFD56858); // +8-10% lightness

  // Shape tokens
  static const double radiusLarge = 24.0;
  static const double radiusMedium = 16.0;
  static const double radiusSmall = 12.0;
  static const double radiusPill = 999.0;

  static const BorderRadius borderRadiusLarge =
      BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusMedium =
      BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusSmall =
      BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusPill =
      BorderRadius.all(Radius.circular(radiusPill));

  // Spacing tokens (4px grid)
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space12 = 48.0;

  // Motion tokens
  static const Duration motionMicro = Duration(milliseconds: 150);
  static const Duration motionStandard = Duration(milliseconds: 300);
  static const Duration motionHero = Duration(milliseconds: 450);

  // Motion curves
  static const Curve curveSpring = Curves.easeOutBack;
  static const Curve curveEnter = Curves.easeOutCubic;
  static const Curve curveExit = Curves.easeInCubic;
}

// Top-level named token constants
const Color brandInk = AppTokens.brandInk;
const Color brandHighlight = AppTokens.brandHighlight;
const Color surfaceCream = AppTokens.surfaceCream;
const Color surfaceCreamAlt = AppTokens.surfaceCreamAlt;
const Color surfaceCreamAlt2 = AppTokens.surfaceCreamAlt2;
const Color background = AppTokens.background;
const Color textSecondary = AppTokens.textSecondary;
const Color divider = AppTokens.divider;
const Color success = AppTokens.success;
const Color warning = AppTokens.warning;
const Color error = AppTokens.error;

const Color brandInkDark = AppTokens.brandInkDark;
const Color brandHighlightDark = AppTokens.brandHighlightDark;
const Color surfaceCreamDark = AppTokens.surfaceCreamDark;
const Color surfaceCreamAltDark = AppTokens.surfaceCreamAltDark;
const Color surfaceCreamAlt2Dark = AppTokens.surfaceCreamAlt2Dark;
const Color backgroundDark = AppTokens.backgroundDark;
const Color textSecondaryDark = AppTokens.textSecondaryDark;
const Color dividerDark = AppTokens.dividerDark;
const Color successDark = AppTokens.successDark;
const Color warningDark = AppTokens.warningDark;
const Color errorDark = AppTokens.errorDark;

const double radiusLarge = AppTokens.radiusLarge;
const double radiusMedium = AppTokens.radiusMedium;
const double radiusSmall = AppTokens.radiusSmall;
const double radiusPill = AppTokens.radiusPill;

const double space1 = AppTokens.space1;
const double space2 = AppTokens.space2;
const double space3 = AppTokens.space3;
const double space4 = AppTokens.space4;
const double space5 = AppTokens.space5;
const double space6 = AppTokens.space6;
const double space8 = AppTokens.space8;
const double space12 = AppTokens.space12;

const Duration motionMicro = AppTokens.motionMicro;
const Duration motionStandard = AppTokens.motionStandard;
const Duration motionHero = AppTokens.motionHero;

/// Custom ThemeExtension providing brand semantic colors and styles that
/// do not map 1:1 onto standard Flutter ThemeData fields.
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color brandInk;
  final Color brandHighlight;
  final Color surfaceCream;
  final Color surfaceCreamAlt;
  final Color surfaceCreamAlt2;
  final Color background;
  final Color textSecondary;
  final Color divider;
  final Color success;
  final Color warning;
  final Color error;

  // Status badge backgrounds (15% opacity per DESIGN_TOKENS.md)
  final Color successBackground;
  final Color warningBackground;
  final Color errorBackground;

  const AppThemeExtension({
    required this.brandInk,
    required this.brandHighlight,
    required this.surfaceCream,
    required this.surfaceCreamAlt,
    required this.surfaceCreamAlt2,
    required this.background,
    required this.textSecondary,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
    required this.successBackground,
    required this.warningBackground,
    required this.errorBackground,
  });

  static const light = AppThemeExtension(
    brandInk: AppTokens.brandInk,
    brandHighlight: AppTokens.brandHighlight,
    surfaceCream: AppTokens.surfaceCream,
    surfaceCreamAlt: AppTokens.surfaceCreamAlt,
    surfaceCreamAlt2: AppTokens.surfaceCreamAlt2,
    background: AppTokens.background,
    textSecondary: AppTokens.textSecondary,
    divider: AppTokens.divider,
    success: AppTokens.success,
    warning: AppTokens.warning,
    error: AppTokens.error,
    successBackground: Color(0x264D8B5F), // 15% opacity of #4D8B5F
    warningBackground: Color(0x26C9832A), // 15% opacity of #C9832A
    errorBackground: Color(0x26C1503F), // 15% opacity of #C1503F
  );

  static const dark = AppThemeExtension(
    brandInk: AppTokens.brandInkDark,
    brandHighlight: AppTokens.brandHighlightDark,
    surfaceCream: AppTokens.surfaceCreamDark,
    surfaceCreamAlt: AppTokens.surfaceCreamAltDark,
    surfaceCreamAlt2: AppTokens.surfaceCreamAlt2Dark,
    background: AppTokens.backgroundDark,
    textSecondary: AppTokens.textSecondaryDark,
    divider: AppTokens.dividerDark,
    success: AppTokens.successDark,
    warning: AppTokens.warningDark,
    error: AppTokens.errorDark,
    successBackground: Color(0x2662A877), // 15% opacity of #62A877
    warningBackground: Color(0x26DE9A42), // 15% opacity of #DE9A42
    errorBackground: Color(0x26D56858), // 15% opacity of #D56858
  );

  @override
  AppThemeExtension copyWith({
    Color? brandInk,
    Color? brandHighlight,
    Color? surfaceCream,
    Color? surfaceCreamAlt,
    Color? surfaceCreamAlt2,
    Color? background,
    Color? textSecondary,
    Color? divider,
    Color? success,
    Color? warning,
    Color? error,
    Color? successBackground,
    Color? warningBackground,
    Color? errorBackground,
  }) {
    return AppThemeExtension(
      brandInk: brandInk ?? this.brandInk,
      brandHighlight: brandHighlight ?? this.brandHighlight,
      surfaceCream: surfaceCream ?? this.surfaceCream,
      surfaceCreamAlt: surfaceCreamAlt ?? this.surfaceCreamAlt,
      surfaceCreamAlt2: surfaceCreamAlt2 ?? this.surfaceCreamAlt2,
      background: background ?? this.background,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      successBackground: successBackground ?? this.successBackground,
      warningBackground: warningBackground ?? this.warningBackground,
      errorBackground: errorBackground ?? this.errorBackground,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      brandInk: Color.lerp(brandInk, other.brandInk, t)!,
      brandHighlight: Color.lerp(brandHighlight, other.brandHighlight, t)!,
      surfaceCream: Color.lerp(surfaceCream, other.surfaceCream, t)!,
      surfaceCreamAlt: Color.lerp(surfaceCreamAlt, other.surfaceCreamAlt, t)!,
      surfaceCreamAlt2:
          Color.lerp(surfaceCreamAlt2, other.surfaceCreamAlt2, t)!,
      background: Color.lerp(background, other.background, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      successBackground:
          Color.lerp(successBackground, other.successBackground, t)!,
      warningBackground:
          Color.lerp(warningBackground, other.warningBackground, t)!,
      errorBackground:
          Color.lerp(errorBackground, other.errorBackground, t)!,
    );
  }
}

/// Typography scale definitions using GoogleFonts Playfair Display and Inter.
abstract final class AppTypography {
  static TextStyle screenTitle({required Color color}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle sectionHeader({required Color color}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
      );

  static TextStyle body({required Color color}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle labelCaption({required Color color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle statNumber({required Color color}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: color,
      );
}

/// AppTheme builds light and dark ThemeData for Slice & Serve Admin.
abstract final class AppTheme {
  static ThemeData get light => _buildTheme(brightness: Brightness.light);
  static ThemeData get dark => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppThemeExtension.dark : AppThemeExtension.light;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppTokens.brandInkDark,
            onPrimary: AppTokens.brandInk,
            secondary: AppTokens.brandHighlight,
            onSecondary: AppTokens.brandInk,
            surface: AppTokens.surfaceCreamDark,
            onSurface: AppTokens.brandInkDark,
            onSurfaceVariant: AppTokens.textSecondaryDark,
            outline: AppTokens.dividerDark,
            error: AppTokens.errorDark,
            onError: AppTokens.brandInk,
          )
        : const ColorScheme.light(
            primary: AppTokens.brandInk,
            onPrimary: AppTokens.surfaceCream,
            secondary: AppTokens.brandHighlight,
            onSecondary: AppTokens.brandInk,
            surface: AppTokens.surfaceCream,
            onSurface: AppTokens.brandInk,
            onSurfaceVariant: AppTokens.textSecondary,
            outline: AppTokens.divider,
            error: AppTokens.error,
            onError: Colors.white,
          );

    final textTheme = TextTheme(
      displaySmall: AppTypography.statNumber(color: colors.brandInk),
      headlineMedium: AppTypography.screenTitle(color: colors.brandInk),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.brandInk,
      ),
      titleLarge: AppTypography.screenTitle(color: colors.brandInk),
      titleMedium: AppTypography.sectionHeader(color: colors.brandInk),
      titleSmall: GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.brandInk,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colors.brandInk,
        height: 1.4,
      ),
      bodyMedium: AppTypography.body(color: colors.brandInk),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.brandInk,
      ),
      labelMedium: AppTypography.labelCaption(color: colors.textSecondary),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colors.textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      cardTheme: CardThemeData(
        color: colors.surfaceCream,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusLarge,
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.brandInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.screenTitle(color: colors.brandInk).copyWith(
          fontSize: 22,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppTokens.brandHighlight,
          foregroundColor: AppTokens.brandInk, // Dark text on yellow for legibility
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.brandInk,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: colors.divider),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brandInk,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfaceCream,
        selectedItemColor:
            isDark ? AppTokens.brandHighlight : AppTokens.brandInk,
        unselectedItemColor: colors.textSecondary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceCream,
        indicatorColor: AppTokens.brandHighlight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.brandInk,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppTokens.brandInk);
          }
          return IconThemeData(color: colors.textSecondary);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceCream,
        border: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMedium,
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMedium,
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMedium,
          borderSide: BorderSide(color: colors.brandInk, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: colors.textSecondary,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 15,
          color: colors.brandInk,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space4,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceCream,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusLarge,
        ),
        titleTextStyle: AppTypography.screenTitle(color: colors.brandInk).copyWith(
          fontSize: 20,
        ),
        contentTextStyle: AppTypography.body(color: colors.brandInk),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusLarge),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTokens.brandInk;
          }
          return colors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTokens.brandHighlight;
          }
          return colors.divider;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}

/// Convenience extension on BuildContext to access AppThemeExtension.
extension ThemeContextX on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>() ?? AppThemeExtension.light;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
