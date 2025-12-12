import 'package:flutter/material.dart';

/// EXPO to WORLD Typography System
/// Based on Designer Agent.md specifications
/// 
/// Primary Font (Latin): Manrope
/// Primary Font (Chinese): Source Han Sans SC (思源黑体SC)
class AppTypography {
  AppTypography._();

  // ============================================
  // FONT FAMILIES
  // ============================================
  
  static const String fontFamilyLatin = 'Manrope';
  static const String fontFamilyChinese = 'SourceHanSansSC';

  // ============================================
  // FONT WEIGHTS
  // ============================================
  
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ============================================
  // DISPLAY STYLES (Hero headlines)
  // ============================================
  
  static TextStyle displayLarge({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 64,
    fontWeight: extraBold,
    letterSpacing: -0.03 * 64, // tracking-[-0.03em]
    height: 1.1, // leading-tight
    color: color,
  );

  static TextStyle displayMedium({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 56,
    fontWeight: bold,
    letterSpacing: -0.03 * 56,
    height: 1.1,
    color: color,
  );

  static TextStyle displaySmall({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 48,
    fontWeight: bold,
    letterSpacing: -0.03 * 48,
    height: 1.1,
    color: color,
  );

  // ============================================
  // HEADLINE STYLES (Section headers)
  // ============================================
  
  static TextStyle h1({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 40,
    fontWeight: bold,
    letterSpacing: -0.02 * 40, // tracking-tight
    height: 1.2,
    color: color,
  );

  static TextStyle h2({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 32,
    fontWeight: semiBold,
    letterSpacing: -0.02 * 32,
    height: 1.25,
    color: color,
  );

  static TextStyle h3({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 24,
    fontWeight: semiBold,
    letterSpacing: -0.02 * 24,
    height: 1.3,
    color: color,
  );

  static TextStyle h4({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 20,
    fontWeight: semiBold,
    letterSpacing: -0.01 * 20,
    height: 1.35,
    color: color,
  );

  static TextStyle h5({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 18,
    fontWeight: semiBold,
    letterSpacing: -0.01 * 18,
    height: 1.4,
    color: color,
  );

  // ============================================
  // BODY STYLES (Content text)
  // ============================================
  
  static TextStyle bodyLarge({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 18,
    fontWeight: regular,
    height: 1.6, // leading-relaxed
    color: color,
  );

  static TextStyle bodyMedium({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 16,
    fontWeight: regular,
    height: 1.5,
    color: color,
  );

  static TextStyle bodySmall({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 14,
    fontWeight: regular,
    height: 1.5,
    color: color,
  );

  // ============================================
  // LABEL & CAPTION STYLES
  // ============================================
  
  static TextStyle labelLarge({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.4,
    color: color,
  );

  static TextStyle labelMedium({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5, // tracking-widest
    height: 1.3,
    color: color,
  );

  static TextStyle labelSmall({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 10,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.3,
    color: color,
  );

  static TextStyle caption({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 12,
    fontWeight: regular,
    height: 1.4,
    color: color,
  );

  // ============================================
  // BUTTON STYLES
  // ============================================
  
  static TextStyle buttonLarge({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 16,
    fontWeight: semiBold,
    letterSpacing: 0.5,
    height: 1.0,
    color: color,
  );

  static TextStyle buttonMedium({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 14,
    fontWeight: semiBold,
    letterSpacing: 0.5,
    height: 1.0,
    color: color,
  );

  static TextStyle buttonSmall({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 12,
    fontWeight: semiBold,
    letterSpacing: 0.5,
    height: 1.0,
    color: color,
  );

  // ============================================
  // PRICE STYLES (for product cards)
  // ============================================
  
  static TextStyle priceLarge({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 24,
    fontWeight: bold,
    height: 1.0,
    color: color,
  );

  static TextStyle priceMedium({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 18,
    fontWeight: bold,
    height: 1.0,
    color: color,
  );

  static TextStyle priceSmall({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 14,
    fontWeight: bold,
    height: 1.0,
    color: color,
  );

  // ============================================
  // NAVIGATION STYLES
  // ============================================
  
  static TextStyle navLabel({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 10,
    fontWeight: medium,
    height: 1.0,
    color: color,
  );

  static TextStyle navLabelActive({Color? color}) => TextStyle(
    fontFamily: fontFamilyLatin,
    fontSize: 10,
    fontWeight: semiBold,
    height: 1.0,
    color: color,
  );

  // ============================================
  // STATIC GETTERS (for direct access without function call)
  // These provide TextStyle objects that can use .copyWith()
  // ============================================
  
  // Headlines
  static TextStyle get headlineLarge => h1();
  static TextStyle get headlineMedium => h2();
  static TextStyle get headlineSmall => h3();
  static TextStyle get titleLarge => h4();
  static TextStyle get titleMedium => h5();
  static TextStyle get titleSmall => labelLarge();
  
  // Body styles as getters
  static TextStyle get bodyLargeStyle => bodyLarge();
  static TextStyle get bodyMediumStyle => bodyMedium();
  static TextStyle get bodySmallStyle => bodySmall();
  
  // Label styles as getters  
  static TextStyle get labelLargeStyle => labelLarge();
  static TextStyle get labelMediumStyle => labelMedium();
  static TextStyle get labelSmallStyle => labelSmall();
  static TextStyle get captionStyle => caption();
}
