import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../utils/responsive_utils.dart';

class AppTextStyles {
  // Major Headers (e.g., "热门推荐", "消息")
  static TextStyle get majorHeader => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w800, // ExtraBold
    color: AppColors.primaryText,
  );
  
  // Card/Item Titles (e.g., Product Names)
  static TextStyle get cardTitle => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.primaryText,
  );
  
  // Body & Descriptions
  static TextStyle get body => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.primaryText,
  );
  
  static TextStyle get bodySmall => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.secondaryText,
  );
  
  // Buttons & Tabs
  static TextStyle get button => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.white,
  );
  
  static TextStyle get buttonSmall => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.white,
  );
  
  // Navigation
  static TextStyle get navActive => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.themeRed,
  );
  
  static TextStyle get navInactive => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.secondaryText,
  );
  
  // Prices
  static TextStyle get priceMain => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.themeRed,
  );
  
  static TextStyle get priceStrikethrough => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.secondaryText,
    decoration: TextDecoration.lineThrough,
  );
  
  // Stock Info
  static TextStyle get stockInfo => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.themeRed,
  );
  
  // Service Module Labels
  static TextStyle get moduleLabel => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.primaryText,
  );
  
  // Location Text
  static TextStyle get locationCity => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.primaryText,
  );
  
  static TextStyle get locationStore => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.themeRed,
  );

  // Responsive Text Styles
  // These methods take a BuildContext to calculate responsive font sizes

  static TextStyle responsiveMajorHeader(BuildContext context) => GoogleFonts.manrope(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 22),
    fontWeight: FontWeight.w800, // ExtraBold
    color: AppColors.primaryText,
  );

  static TextStyle responsiveCardTitle(BuildContext context) => GoogleFonts.manrope(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.primaryText,
  );

  static TextStyle responsiveBody(BuildContext context) => GoogleFonts.manrope(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.primaryText,
  );

  static TextStyle responsiveBodySmall(BuildContext context) => GoogleFonts.manrope(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
    fontWeight: FontWeight.w400, // Regular
    color: AppColors.secondaryText,
  );

  static TextStyle responsiveButton(BuildContext context) => GoogleFonts.manrope(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.white,
  );

  static TextStyle responsiveLocationCity(BuildContext context) => GoogleFonts.manrope(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.primaryText,
  );

  static TextStyle responsiveLocationStore(BuildContext context) => GoogleFonts.manrope(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
    fontWeight: FontWeight.w600, // SemiBold
    color: AppColors.themeRed,
  );

  static TextStyle responsivePriceMain(BuildContext context) => GoogleFonts.manrope(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
    fontWeight: FontWeight.w700, // Bold
    color: AppColors.themeRed,
  );
}
