import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// EXPO to WORLD Theme Configuration
/// Supports both Light and Dark modes with equal polish
class AppTheme {
  AppTheme._();

  // ============================================
  // DARK THEME
  // ============================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamilyLatin,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.themeRed,
        onPrimary: Colors.white,
        secondary: AppColors.blue,
        onSecondary: Colors.white,
        tertiary: AppColors.yellow,
        surface: AppColors.darkBackgroundElevated,
        onSurface: AppColors.darkForeground,
        error: AppColors.themeRedLight,
        onError: Colors.white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.darkBackgroundBase,
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(
          color: AppColors.darkForeground,
          size: AppSpacing.iconMd,
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamilyLatin,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkForeground,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.darkBackgroundElevated.withValues(alpha: 0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.themeRed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.buttonMedium(),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.themeRed,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.buttonMedium(),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkForeground,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          textStyle: AppTypography.buttonMedium(),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkBackgroundBase,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.themeRed,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.themeRedLight,
            width: 1,
          ),
        ),
        hintStyle: AppTypography.bodyMedium(
          color: AppColors.darkForegroundSubtle,
        ),
        labelStyle: AppTypography.bodyMedium(
          color: AppColors.darkForegroundMuted,
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.themeRed,
        unselectedItemColor: AppColors.darkForegroundSubtle,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: false,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.darkForeground,
        size: AppSpacing.iconMd,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        tileColor: Colors.transparent,
        iconColor: AppColors.darkForegroundMuted,
        textColor: AppColors.darkForeground,
      ),
    );
  }

  // ============================================
  // LIGHT THEME
  // ============================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamilyLatin,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.themeRed,
        onPrimary: Colors.white,
        secondary: AppColors.blue,
        onSecondary: Colors.white,
        tertiary: AppColors.yellow,
        surface: AppColors.lightBackgroundElevated,
        onSurface: AppColors.lightForeground,
        error: AppColors.themeRed,
        onError: Colors.white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.lightBackgroundBase,
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(
          color: AppColors.lightForeground,
          size: AppSpacing.iconMd,
        ),
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamilyLatin,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.themeRed,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.buttonMedium(),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.themeRed,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.buttonMedium(),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightForeground,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
          textStyle: AppTypography.buttonMedium(),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.themeRed,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: const BorderSide(
            color: AppColors.themeRed,
            width: 1,
          ),
        ),
        hintStyle: AppTypography.bodyMedium(
          color: AppColors.lightForegroundSubtle,
        ),
        labelStyle: AppTypography.bodyMedium(
          color: AppColors.lightForegroundMuted,
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.themeRed,
        unselectedItemColor: AppColors.lightForegroundSubtle,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: false,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.lightForeground,
        size: AppSpacing.iconMd,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        tileColor: Colors.transparent,
        iconColor: AppColors.lightForegroundMuted,
        textColor: AppColors.lightForeground,
      ),
    );
  }
}
