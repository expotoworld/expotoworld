import 'package:flutter/material.dart';

/// EXPO to WORLD Design System Colors
/// Based on Designer Agent.md and App Design & Brand Guidelines.md
/// 
/// This file defines ALL colors used in the application.
/// ONLY use colors from this file - no hardcoded colors elsewhere.
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY BRAND COLORS
  // ============================================
  
  /// Theme Red - Primary accent color for CTAs, links, active states
  static const Color themeRed = Color(0xFFEE3432);
  static const Color themeRedDark = Color(0xFFB82025);
  static const Color themeRedDarker = Color(0xFF7A1619);
  static const Color themeRedLight = Color(0xFFFF5252);
  static const Color themeRedLightest = Color(0xFFFCE8E8);
  
  // Red palette aliases
  static const Color red500 = themeRed;
  static const Color red400 = themeRedLight;
  static const Color red600 = themeRedDark;
  static const Color red700 = themeRedDarker;
  static const Color red100 = themeRedLightest;

  // ============================================
  // SEMANTIC COLOR PALETTE
  // ============================================
  
  // Blues
  static const Color blue = Color(0xFF0066CC);
  static const Color blueDark = Color(0xFF004B91);
  static const Color blueDarker = Color(0xFF0F2C4C);
  static const Color teal = Color(0xFF008080);
  static const Color blueMuted = Color(0xFF4A6C8C);
  
  // Blue palette aliases
  static const Color blue500 = blue;
  static const Color blue600 = blueDark;
  static const Color blue700 = blueDarker;

  // Yellows
  static const Color yellow = Color(0xFFFFC107);
  static const Color yellowDark = Color(0xFFF5A623);
  static const Color yellowMuted = Color(0xFFC5A059);
  static const Color yellowDarker = Color(0xFF9C7C38);
  static const Color yellowLightest = Color(0xFFFFF8E1);
  
  // Yellow palette aliases
  static const Color yellow500 = yellow;
  static const Color yellow400 = yellowDark;
  static const Color yellow100 = yellowLightest;

  // Greens
  static const Color green = Color(0xFF107C10);
  static const Color greenDark = Color(0xFF0A4D0A);
  static const Color greenLight = Color(0xFF2ECC71);
  static const Color greenMuted = Color(0xFF8FA395);
  static const Color greenLightest = Color(0xFFE6F4EA);
  
  // Green palette aliases
  static const Color green500 = green;
  static const Color green400 = greenLight;
  static const Color green600 = greenDark;
  static const Color green100 = greenLightest;

  // Neutrals
  static const Color neutralLightest = Color(0xFFF8F9FA);
  static const Color neutralLight = Color(0xFFF1F1F1);
  static const Color neutralMid = Color(0xFFD1D5DB);
  static const Color neutralDark = Color(0xFF4A4A4A);
  static const Color neutralDarkest = Color(0xFF121212);
  
  // Neutral palette aliases
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF000000);
  static const Color neutralGray100 = neutralLightest;
  static const Color neutralGray200 = neutralLight;
  static const Color neutralGray300 = neutralMid;
  static const Color neutralGray400 = Color(0xFF9CA3AF);
  static const Color neutralGray500 = Color(0xFF6B7280);
  static const Color neutralGray600 = neutralDark;
  static const Color neutralGray700 = Color(0xFF374151);
  static const Color neutralGray800 = Color(0xFF1F2937);
  static const Color neutralGray900 = neutralDarkest;

  // Exotic/Accent Colors
  static const Color purple = Color(0xFF6A1B9A);
  static const Color orange = Color(0xFFFF5722);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color purpleDark = Color(0xFF4A2C58);
  static const Color slate = Color(0xFF607D8B);
  
  // Exotic palette aliases
  static const Color exoticPurple = purple;
  static const Color exoticCoral = Color(0xFFFF6B6B);
  static const Color exoticTeal = teal;

  // ============================================
  // DARK MODE SEMANTIC TOKENS
  // ============================================
  
  static const Color darkBackgroundDeep = Color(0xFF121212);
  static const Color darkBackgroundBase = Color(0xFF121212);
  static const Color darkBackgroundElevated = Color(0xFF4A4A4A);
  static const Color darkSurface = Color(0x0DF8F9FA); // 5% opacity
  static const Color darkSurfaceHover = Color(0x1AF8F9FA); // 10% opacity
  static const Color darkForeground = Color(0xFFF1F1F1);
  static const Color darkForegroundMuted = Color(0xFFD1D5DB);
  static const Color darkForegroundSubtle = Color(0xFF4A4A4A);
  static const Color darkBorderDefault = Color(0xFF4A4A4A);
  static const Color darkBorderHover = Color(0xFFD1D5DB);
  static const Color darkBorderAccent = themeRed;

  // ============================================
  // LIGHT MODE SEMANTIC TOKENS
  // ============================================
  
  static const Color lightBackgroundDeep = Color(0xFFF8F9FA);
  static const Color lightBackgroundBase = Color(0xFFF8F9FA);
  static const Color lightBackgroundElevated = Color(0xFFF1F1F1);
  static const Color lightSurface = Color(0x0D121212); // 5% opacity
  static const Color lightSurfaceHover = Color(0x1A121212); // 10% opacity
  static const Color lightForeground = Color(0xFF121212);
  static const Color lightForegroundMuted = Color(0xFF4A4A4A);
  static const Color lightForegroundSubtle = Color(0xFFD1D5DB);
  static const Color lightBorderDefault = Color(0xFFD1D5DB);
  static const Color lightBorderHover = Color(0xFF4A4A4A);
  static const Color lightBorderAccent = themeRed;

  // ============================================
  // ACCENT GLOW COLORS (with opacity)
  // ============================================
  
  static const Color accentGlowDark = Color(0x4DEE3432); // 30% opacity
  static const Color accentGlowLight = Color(0x26EE3432); // 15% opacity

  // ============================================
  // GRADIENT DEFINITIONS
  // ============================================
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [themeRed, purple, blue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x14FFFFFF), // 8% white
      Color(0x05FFFFFF), // 2% white
    ],
  );

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Returns the appropriate color based on brightness
  static Color adaptive({
    required BuildContext context,
    required Color light,
    required Color dark,
  }) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  /// Returns foreground color based on current theme
  static Color foreground(BuildContext context) {
    return adaptive(
      context: context,
      light: lightForeground,
      dark: darkForeground,
    );
  }

  /// Returns muted foreground color based on current theme
  static Color foregroundMuted(BuildContext context) {
    return adaptive(
      context: context,
      light: lightForegroundMuted,
      dark: darkForegroundMuted,
    );
  }

  /// Returns subtle foreground color based on current theme
  static Color foregroundSubtle(BuildContext context) {
    return adaptive(
      context: context,
      light: lightForegroundSubtle,
      dark: darkForegroundSubtle,
    );
  }

  /// Returns background color based on current theme
  static Color background(BuildContext context) {
    return adaptive(
      context: context,
      light: lightBackgroundBase,
      dark: darkBackgroundBase,
    );
  }

  /// Returns elevated surface color based on current theme
  static Color surfaceElevated(BuildContext context) {
    return adaptive(
      context: context,
      light: lightBackgroundElevated,
      dark: darkBackgroundElevated,
    );
  }

  /// Returns border color based on current theme
  static Color border(BuildContext context) {
    return adaptive(
      context: context,
      light: lightBorderDefault,
      dark: darkBorderDefault,
    );
  }
}
