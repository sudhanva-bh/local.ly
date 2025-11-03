import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central Theme setup for Locally
///
/// Contains both light and dark ThemeData objects derived from AppColors.
/// Plug into your MaterialApp:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
/// )
/// ```
class AppTheme {
  const AppTheme._();

  // ─────────────────────────────
  // 🌞 LIGHT THEME
  // ─────────────────────────────
  static ThemeData get light {
    final colors = AppColors.light;

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        secondary: colors.secondary,
        tertiary: colors.tertiary,
        background: colors.background,
        surface: colors.surface,
        surfaceDim: colors.surfaceDim,
        error: colors.error,
        onPrimary: colors.onPrimary,
        onSecondary: colors.onSecondary,
        onBackground: colors.onBackground,
        onSurface: colors.onSurface,
        onError: colors.onPrimary,
        outline: colors.outline,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.onBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.onBackground),
        titleTextStyle: TextStyle(
          color: colors.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 2,
        shadowColor: colors.dropShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),

      // Input Decoration (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceDim,
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),

      // Text
      textTheme: _textTheme(colors),
    );
  }

  // ─────────────────────────────
  // 🌚 DARK THEME
  // ─────────────────────────────
  static ThemeData get dark {
    final colors = AppColors.dark;

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        secondary: colors.secondary,
        tertiary: colors.tertiary,
        background: colors.background,
        surface: colors.surface,
        surfaceDim: colors.surfaceDim,
        error: colors.error,
        onPrimary: colors.onPrimary,
        onSecondary: colors.onSecondary,
        onBackground: colors.onBackground,
        onSurface: colors.onSurface,
        onError: colors.onPrimary,
        outline: colors.outline,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.onBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.onBackground),
        titleTextStyle: TextStyle(
          color: colors.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 2,
        shadowColor: colors.dropShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primaryLight,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceDim,
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),

      textTheme: _textTheme(colors),
    );
  }

  // ─────────────────────────────
  // 📄 TEXT THEME
  // ─────────────────────────────
  static TextTheme _textTheme(dynamic colors) {
    // Create your base text theme
    final base = TextTheme(
      displayLarge: TextStyle(
        color: colors.onBackground,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: colors.onBackground,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: colors.onSurface,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: colors.onSurfaceVariant,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: colors.onPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );

    // Apply the Manrope font to all text styles
    return GoogleFonts.manropeTextTheme(base);
  }
}
