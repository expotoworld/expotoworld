import 'package:flutter/material.dart';

/// Utility class for responsive design calculations
class ResponsiveUtils {
  /// Device size categories
  static const double _smallScreenThreshold = 667.0; // iPhone SE height
  static const double _mediumScreenThreshold = 812.0; // iPhone 12/13 height
  static const double _largeScreenThreshold = 926.0; // iPhone 14 Pro Max height

  /// Get device category based on screen height
  static DeviceSize getDeviceSize(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (screenHeight <= _smallScreenThreshold) {
      return DeviceSize.small;
    } else if (screenHeight <= _mediumScreenThreshold) {
      return DeviceSize.medium;
    } else if (screenHeight <= _largeScreenThreshold) {
      return DeviceSize.large;
    } else {
      return DeviceSize.extraLarge; // Tablets and very large phones
    }
  }

  /// Calculate optimal bottom sheet height based on device size and content
  static double getBottomSheetHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final deviceSize = getDeviceSize(context);

    // Base height percentages for different device sizes
    double heightPercentage;
    double minHeight;
    double maxHeight;

    switch (deviceSize) {
      case DeviceSize.small:
        // iPhone SE and similar - use more conservative height
        heightPercentage = 0.35; // 35% - increased to accommodate content
        minHeight = 300.0;
        maxHeight = 350.0;
        break;
      case DeviceSize.medium:
        // Standard iPhones - balanced height
        heightPercentage = 0.33; // 33% - increased to accommodate content
        minHeight = 320.0;
        maxHeight = 380.0;
        break;
      case DeviceSize.large:
        // Large iPhones - need more height due to responsive spacing
        heightPercentage = 0.32; // 32% - increased to accommodate responsive spacing
        minHeight = 350.0;
        maxHeight = 420.0;
        break;
      case DeviceSize.extraLarge:
        // Tablets and very large devices - need more height for responsive content
        heightPercentage = 0.30; // 30% - increased to accommodate responsive spacing
        minHeight = 380.0;
        maxHeight = 500.0;
        break;
    }

    // Calculate height with device-specific constraints
    final calculatedHeight = screenHeight * heightPercentage;

    return calculatedHeight.clamp(minHeight, maxHeight);
  }

  /// Get responsive padding based on device size
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double smallMultiplier = 1.0,
    double mediumMultiplier = 1.0,
    double largeMultiplier = 1.0,
    double extraLargeMultiplier = 1.0,
  }) {
    final deviceSize = getDeviceSize(context);
    const basePadding = 16.0;
    
    double multiplier;
    switch (deviceSize) {
      case DeviceSize.small:
        multiplier = smallMultiplier;
        break;
      case DeviceSize.medium:
        multiplier = mediumMultiplier;
        break;
      case DeviceSize.large:
        multiplier = largeMultiplier;
        break;
      case DeviceSize.extraLarge:
        multiplier = extraLargeMultiplier;
        break;
    }
    
    final padding = basePadding * multiplier;
    return EdgeInsets.all(padding);
  }

  /// Get responsive font size based on device size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final deviceSize = getDeviceSize(context);
    
    switch (deviceSize) {
      case DeviceSize.small:
        return baseSize * 0.9; // Slightly smaller on small devices
      case DeviceSize.medium:
        return baseSize; // Base size for medium devices
      case DeviceSize.large:
        return baseSize * 1.05; // Slightly larger on large devices
      case DeviceSize.extraLarge:
        return baseSize * 1.1; // Larger on tablets
    }
  }

  /// Get responsive spacing based on device size
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final deviceSize = getDeviceSize(context);

    switch (deviceSize) {
      case DeviceSize.small:
        return baseSpacing * 0.8; // Tighter spacing on small devices
      case DeviceSize.medium:
        return baseSpacing; // Base spacing for medium devices
      case DeviceSize.large:
        return baseSpacing * 1.05; // Slightly more spacing on large devices (reduced from 1.1)
      case DeviceSize.extraLarge:
        return baseSpacing * 1.1; // More spacing on tablets (reduced from 1.2)
    }
  }

  /// Check if device is considered small screen
  static bool isSmallScreen(BuildContext context) {
    return getDeviceSize(context) == DeviceSize.small;
  }

  /// Check if device is considered large screen
  static bool isLargeScreen(BuildContext context) {
    final deviceSize = getDeviceSize(context);
    return deviceSize == DeviceSize.large || deviceSize == DeviceSize.extraLarge;
  }
}

/// Device size categories
enum DeviceSize {
  small,      // iPhone SE, iPhone 8 and similar
  medium,     // iPhone 12, 13, 14 standard
  large,      // iPhone 12/13/14 Pro Max
  extraLarge, // Tablets and very large devices
}
