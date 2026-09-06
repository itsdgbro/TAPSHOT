import 'package:flutter/material.dart';

/// Available visual target and HUD themes
enum AppSkin {
  volt,       // Default Acid Yellow / Volt
  cyberpunk,  // Electric Magenta & Neon Cyan
  crimson,    // Blazing Crimson Red
  frost,      // Pure Ice White & Cyan
}

extension AppSkinExtension on AppSkin {
  String get nameUpper {
    switch (this) {
      case AppSkin.volt:
        return 'VOLT TECH';
      case AppSkin.cyberpunk:
        return 'CYBERPUNK';
      case AppSkin.crimson:
        return 'CRIMSON';
      case AppSkin.frost:
        return 'FROST';
    }
  }

  String get description {
    switch (this) {
      case AppSkin.volt:
        return 'High-voltage electric acid-yellow.';
      case AppSkin.cyberpunk:
        return 'Neon magenta & electric cyan arcade vibes.';
      case AppSkin.crimson:
        return 'Aggressive hyper-focus crimson.';
      case AppSkin.frost:
        return 'Sub-zero crystalline ice white.';
    }
  }

  Color get primaryAccent {
    switch (this) {
      case AppSkin.volt:
        return const Color(0xFFCCFF00); // Acid yellow
      case AppSkin.cyberpunk:
        return const Color(0xFFFF007F); // Neon Magenta
      case AppSkin.crimson:
        return const Color(0xFFFF2A4B); // Crimson Red
      case AppSkin.frost:
        return const Color(0xFFE0F7FA); // Frost White
    }
  }

  Color get secondaryAccent {
    switch (this) {
      case AppSkin.volt:
        return const Color(0xFF00E5FF); // Precision Cyan
      case AppSkin.cyberpunk:
        return const Color(0xFF00F0FF); // Cyan
      case AppSkin.crimson:
        return const Color(0xFFFF9100); // Amber
      case AppSkin.frost:
        return const Color(0xFF00B0FF); // Glacier Blue
    }
  }

  int get unlockScoreRequirement {
    switch (this) {
      case AppSkin.volt:
        return 0; // Unlocked from start
      case AppSkin.cyberpunk:
        return 300;
      case AppSkin.crimson:
        return 800;
      case AppSkin.frost:
        return 1500;
    }
  }
}
