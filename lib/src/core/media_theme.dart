// ============================================================
// FILE: lib/src/core/media_theme.dart
// NextGen Media Utility — Consistent Design System & Theme
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Central design tokens for the NextGen Media Utility package.
///
/// All screens and widgets reference these constants to guarantee a
/// consistent look-and-feel across every feature module.
class MediaTheme {
  MediaTheme._();

  // ── Brand palette ──────────────────────────────────────────
  static const Color primaryNeon    = Color(0xFF6366F1); // Indigo
  static const Color accentGreen    = Color(0xFF10B981); // Emerald success
  static const Color accentAmber    = Color(0xFFF59E0B); // Amber warning
  static const Color accentRed      = Color(0xFFEF4444); // Red error
  static const Color accentBlue     = Color(0xFF2563EB); // Blue info

  // ── Light palette ──────────────────────────────────────────
  static const Color lightPrimary    = Color(0xFF6366F1);
  static const Color lightSecondary  = Color(0xFFEC4899);
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightCard       = Color(0xFFFFFFFF);
  static const Color lightBorder     = Color(0xFFE5E7EB);
  static const Color lightOnSurface  = Color(0xFF111827);
  static const Color lightSubtext    = Color(0xFF6B7280);

  // ── Dark palette ───────────────────────────────────────────
  static const Color darkPrimary    = Color(0xFF818CF8);
  static const Color darkSecondary  = Color(0xFFF472B6);
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface    = Color(0xFF1F2937);
  static const Color darkCard       = Color(0xFF1F2937);
  static const Color darkBorder     = Color(0xFF374151);
  static const Color darkOnSurface  = Color(0xFFF9FAFB);
  static const Color darkSubtext    = Color(0xFF9CA3AF);

  // ── Radius tokens ──────────────────────────────────────────
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 20.0;
  static const double radius2xl = 24.0;

  // ── Shared shape helpers ───────────────────────────────────
  static BorderRadius get borderRadiusSm  => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd  => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg  => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl  => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadius2xl => BorderRadius.circular(radius2xl);

  // ── Card decoration helpers ────────────────────────────────
  static BoxDecoration cardDecoration({
    required Brightness brightness,
    Color? borderColor,
    double radius = radiusLg,
  }) {
    final isDark = brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? darkCard : lightCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? (isDark ? darkBorder : lightBorder),
      ),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  // ── Full ThemeData — Light ─────────────────────────────────
  static ThemeData lightTheme() {
    const colorScheme = ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightSurface,
      error: accentRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightOnSurface,
    );

    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackground,
      fontFamily: 'Roboto',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightOnSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: lightOnSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: lightBorder),
        ),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPrimary,
          side: const BorderSide(color: lightPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: lightPrimary, width: 1.5),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: lightBackground,
        selectedColor: lightPrimary.withValues(alpha: 0.15),
        side: const BorderSide(color: lightBorder),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: lightPrimary,
        thumbColor: lightPrimary,
        inactiveTrackColor: lightPrimary.withValues(alpha: 0.2),
        overlayColor: lightPrimary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius2xl)),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),

      // Icon
      iconTheme: const IconThemeData(color: lightOnSurface, size: 22),
    );
  }

  // ── Full ThemeData — Dark ──────────────────────────────────
  static ThemeData darkTheme() {
    const colorScheme = ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkSurface,
      error: Color(0xFFF87171),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkOnSurface,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: 'Roboto',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: darkOnSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: darkBorder),
        ),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkPrimary, width: 1.5),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: darkPrimary.withValues(alpha: 0.2),
        side: const BorderSide(color: darkBorder),
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: darkPrimary,
        thumbColor: darkPrimary,
        inactiveTrackColor: darkPrimary.withValues(alpha: 0.25),
        overlayColor: darkPrimary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius2xl)),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),

      // Icon
      iconTheme: const IconThemeData(color: darkOnSurface, size: 22),
    );
  }
}
