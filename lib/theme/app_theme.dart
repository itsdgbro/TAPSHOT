import 'package:flutter/material.dart';

/// AppTheme defines the Minimalist Precision / Tech visual aesthetic for TAPSHOT.
/// Palette: Monochrome dark graphite, deep obsidian, high-contrast acid-yellow, precision white, warning crimson.
class AppTheme {
  AppTheme._();

  // Core Palette
  static const Color background = Color(0xFF0D0E12); // Deep graphite
  static const Color surface = Color(0xFF16181F);    // Obsidian surface
  static const Color surfaceElevated = Color(0xFF1F222B); // High-contrast container
  static const Color surfaceBorder = Color(0xFF2E323E);

  static const Color accent = Color(0xFFCCFF00);     // Acid Yellow / Neon Volt
  static const Color accentDim = Color(0xFF88AA00);
  static const Color accentGlow = Color(0x66CCFF00);

  static const Color secondary = Color(0xFF00E5FF);  // Precision Cyan
  static const Color secondaryGlow = Color(0x4400E5FF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E95A5);
  static const Color textMuted = Color(0xFF555B68);

  static const Color danger = Color(0xFFFF3366);     // Warning Crimson
  static const Color dangerGlow = Color(0x66FF3366);
  static const Color success = Color(0xFF00E676);

  // Typography Styles
  static const TextStyle brandTitle = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.w900,
    letterSpacing: 6.0,
    color: textPrimary,
    fontFamilyFallback: ['Roboto', 'sans-serif'],
  );

  static const TextStyle brandTagline = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 3.5,
    color: accent,
  );

  static const TextStyle hudLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
    color: textSecondary,
  );

  static const TextStyle hudValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.0,
    color: textPrimary,
  );

  static const TextStyle comboBanner = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
    color: accent,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.5,
    color: Colors.black,
  );

  static const TextStyle buttonSecondaryText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.0,
    color: textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: textPrimary,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: textSecondary,
  );

  static const TextStyle scoreHighlight = TextStyle(
    fontSize: 54,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
    color: accent,
  );

  // Box Decorations
  static BoxDecoration techCardDecoration({
    Color? borderColor,
    Color? bgColor,
    bool glow = false,
  }) {
    return BoxDecoration(
      color: bgColor ?? surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? surfaceBorder,
        width: 1.5,
      ),
      boxShadow: glow
          ? [
              BoxShadow(
                color: (borderColor ?? accent).withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: secondary,
        surface: surface,
        error: danger,
      ),
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
    );
  }
}
