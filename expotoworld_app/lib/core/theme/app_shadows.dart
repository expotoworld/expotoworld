// EXPO to WORLD Shadow System
// Multi-layer shadows for realistic depth
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  // ============================================
  // CARD SHADOWS - LIGHT MODE
  // ============================================
  
  /// Subtle card shadow for light mode
  static List<BoxShadow> get cardLight => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// Elevated card shadow for light mode
  static List<BoxShadow> get cardElevatedLight => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ============================================
  // CARD SHADOWS - DARK MODE
  // ============================================
  
  /// Card shadow for dark mode with subtle accent glow
  static List<BoxShadow> get cardDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.themeRed.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 0),
    ),
  ];

  /// Elevated card shadow for dark mode
  static List<BoxShadow> get cardElevatedDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: AppColors.themeRed.withValues(alpha: 0.08),
      blurRadius: 30,
      offset: const Offset(0, 0),
    ),
  ];

  // ============================================
  // BUTTON SHADOWS
  // ============================================
  
  /// Primary button shadow with accent glow
  static List<BoxShadow> get buttonPrimary => [
    BoxShadow(
      color: AppColors.themeRed.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.themeRed.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 0),
    ),
  ];

  /// Secondary button shadow
  static List<BoxShadow> get buttonSecondary => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ============================================
  // NAVIGATION SHADOWS
  // ============================================
  
  /// Bottom navigation bar shadow
  static List<BoxShadow> get bottomNav => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];

  /// App bar shadow when scrolled
  static List<BoxShadow> get appBar => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Returns appropriate card shadow based on theme
  static List<BoxShadow> card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardDark
        : cardLight;
  }

  /// Returns appropriate elevated card shadow based on theme
  static List<BoxShadow> cardElevated(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardElevatedDark
        : cardElevatedLight;
  }
}
