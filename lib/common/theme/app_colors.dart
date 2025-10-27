import 'package:flutter/material.dart';

/// Centralized app color palette
/// Contains both Light and Dark theme variants for easy access.
///
/// Use with:
///   - AppColors.light.* for light theme
///   - AppColors.dark.*  for dark theme
///
/// Example: color: AppColors.light.primary
class AppColors {
  // Prevent instantiation
  const AppColors._();

  // ─────────────────────────────
  // 🌞 LIGHT THEME
  // ─────────────────────────────
  static const _LightColors light = _LightColors();

  // ─────────────────────────────
  // 🌚 DARK THEME
  // ─────────────────────────────
  static const _DarkColors dark = _DarkColors();
}

// ════════════════════════════════════════════════════════════════════════════
// LIGHT COLORS
// ════════════════════════════════════════════════════════════════════════════
class _LightColors {
  const _LightColors();

  // Brand & Core
  final Color primary = const Color(0xFFF57634); // Bright orange
  final Color primaryDark = const Color(0xFFE56A00);
  final Color secondary = const Color(0xFF080019); // Navy blue
  final Color tertiary = const Color(0xFFFDDB40); // Yellow accent

  // Backgrounds & Surfaces
  final Color background = const Color(0xFFF4DCC4); // App background (cream)
  final Color surface = const Color(0xFFFFFEFF); // Main surface (cards)
  final Color surfaceDim = const Color.fromARGB(
    255,
    239,
    239,
    239,
  ); // Slight contrast
  final Color blur = const Color(0x7FFFFEFF); // Frosted overlays

  // Text & Content
  final Color onPrimary = const Color(0xFFFFFFFF);
  final Color onSecondary = const Color(0xFFFFFFFF);
  final Color onBackground = const Color(0xFF0D0402);
  final Color onSurface = const Color(0xFF0D0402);
  final Color onSurfaceVariant = const Color(0xFF474641); // Muted text

  // States
  final Color success = const Color(0xFF00C853);
  final Color warning = const Color.fromRGBO(255, 193, 7, 1);
  final Color info = const Color(0xFF2196F3);
  final Color error = const Color(0xFFFF3030);

  // Misc
  final Color divider = const Color(0xFFE0E0E0);
  final Color dropShadow = const Color(0x33000000);
  final Color transparent = Colors.transparent;

  // Gradients
  final LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFFFA421E), Color(0xFFF57634)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.13, 0.72],
  );

  final LinearGradient overlayGradient = const LinearGradient(
    colors: [Color(0x66000000), Color(0x00000000)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// DARK COLORS
// ════════════════════════════════════════════════════════════════════════════
class _DarkColors {
  const _DarkColors();

  // Brand & Core
  final Color primary = const Color(0xFFE56A00); // Slightly dimmed orange
  final Color primaryLight = const Color(0xFFF57634);
  final Color secondary = const Color(0xFFBDBAFF); // Muted navy accent
  final Color tertiary = const Color(0xFFF5C63E); // Softer yellow

  // Backgrounds & Surfaces
  final Color background = const Color(0xFF0D0402);
  final Color surface = const Color(0xFF141212);
  final Color surfaceDim = const Color.fromARGB(255, 38, 37, 37);
  final Color blur = const Color(0x33141212); // For frosted overlays

  // Text & Content
  final Color onPrimary = const Color(0xFFFFFFFF);
  final Color onSecondary = const Color(0xFF0D0402);
  final Color onBackground = const Color(0xFFFDFCFB);
  final Color onSurface = const Color(0xFFECEBE9);
  final Color onSurfaceVariant = const Color(0xFFB9B8B5);

  // States
  final Color success = const Color(0xFF00E676);
  final Color warning = const Color(0xFFFFCA28);
  final Color info = const Color(0xFF64B5F6);
  final Color error = const Color(0xFFFF5252);

  // Misc
  final Color divider = const Color(0xFF262421);
  final Color dropShadow = const Color(0x66000000);
  final Color transparent = Colors.transparent;

  // Gradients
  final LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFFE56A00), Color(0xFFF57634)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.2, 0.8],
  );

  final LinearGradient overlayGradient = const LinearGradient(
    colors: [Color(0x99000000), Color(0x00000000)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );
}
