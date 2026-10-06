// ============================================================
// FILE: lib/src/core/media_theme.dart
// NextGen Media Utility - Theme Configuration
// ============================================================

import 'package:flutter/material.dart';

class MediaTheme {
  // Light theme colors
  static const Color primaryNeon = Color(0xFF6366F1);
  static const Color lightPrimary = Color(0xFF6366F1);
  static const Color lightSecondary = Color(0xFFEC4899);
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Colors.white;

  // Dark theme colors
  static const Color darkPrimary = Color(0xFF818CF8);
  static const Color darkSecondary = Color(0xFFF472B6);
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);

  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        error: Color(0xFFEF4444),
      ),
      scaffoldBackgroundColor: lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        error: Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
