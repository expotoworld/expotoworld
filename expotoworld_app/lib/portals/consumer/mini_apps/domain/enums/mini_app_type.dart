import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// MiniAppType represents the four ETW sub-applications.
enum MiniAppType {
  toB,   // B2B Exposition - MEGA stores
  toC,   // B2C Marketplace - MARKET stores
  toU,   // Unmanned Stores - GO + XPRESS stores
  toX,   // Group buying services - Virtual (no physical stores)
}

extension MiniAppTypeExtension on MiniAppType {
  /// Display name using ETW branding
  String get displayName {
    switch (this) {
      case MiniAppType.toB:
        return 'EXPO to WORLD to B';
      case MiniAppType.toC:
        return 'EXPO to WORLD to C';
      case MiniAppType.toU:
        return 'EXPO to WORLD to U';
      case MiniAppType.toX:
        return 'EXPO to WORLD to X';
    }
  }

  /// Short display name
  String get shortName {
    switch (this) {
      case MiniAppType.toB:
        return 'to B';
      case MiniAppType.toC:
        return 'to C';
      case MiniAppType.toU:
        return 'to U';
      case MiniAppType.toX:
        return 'to X';
    }
  }

  /// Description of the mini-app
  String get description {
    switch (this) {
      case MiniAppType.toB:
        return 'B2B Exposition';
      case MiniAppType.toC:
        return 'B2C Marketplace';
      case MiniAppType.toU:
        return 'Automated Stores';
      case MiniAppType.toX:
        return 'Group Services';
    }
  }

  /// Asset path for the mini-app logo
  String get logoAssetPath {
    switch (this) {
      case MiniAppType.toB:
        return 'assets/mini-apps/toB.svg';
      case MiniAppType.toC:
        return 'assets/mini-apps/toC.svg';
      case MiniAppType.toU:
        return 'assets/mini-apps/toU.svg';
      case MiniAppType.toX:
        return 'assets/mini-apps/toX.svg';
    }
  }

  /// Store types associated with this mini-app
  List<StoreType> get associatedStoreTypes {
    switch (this) {
      case MiniAppType.toB:
        return [StoreType.mega];
      case MiniAppType.toC:
        return [StoreType.market];
      case MiniAppType.toU:
        return [StoreType.toGo, StoreType.xpress];
      case MiniAppType.toX:
        return []; // No physical stores
    }
  }

  /// Whether this mini-app has physical stores
  bool get hasPhysicalStores => associatedStoreTypes.isNotEmpty;

  /// Whether this mini-app has a cart/checkout flow
  bool get hasCart => this != MiniAppType.toX;

  /// Whether this mini-app shows a map
  bool get hasMap => this != MiniAppType.toX;
}

/// StoreType enum for physical stores
enum StoreType {
  mega,    // B2B Exposition stores
  market,  // B2C Marketplace stores
  toGo,    // Automated/Unmanned stores
  xpress,  // Express pickup stores
}

extension StoreTypeExtension on StoreType {
  /// Display name
  String get displayName {
    switch (this) {
      case StoreType.mega:
        return 'MEGA';
      case StoreType.market:
        return 'MARKET';
      case StoreType.toGo:
        return 'to GO';
      case StoreType.xpress:
        return 'XPRESS';
    }
  }

  /// Subtitle description
  String get subtitle {
    switch (this) {
      case StoreType.mega:
        return 'B2B Exposition';
      case StoreType.market:
        return 'B2C Marketplace';
      case StoreType.toGo:
        return 'Automated Store';
      case StoreType.xpress:
        return 'Express Pickup';
    }
  }

  /// Color for this store type (matching super-app)
  /// MEGA=blue, MARKET=green, toGO=purple, XPRESS=yellow
  Color get color {
    switch (this) {
      case StoreType.mega:
        return AppColors.blue500;       // Blue for MEGA
      case StoreType.market:
        return AppColors.green500;      // Green for MARKET
      case StoreType.toGo:
        return AppColors.purple;        // Purple for to GO
      case StoreType.xpress:
        return AppColors.yellow500;     // Yellow for XPRESS
    }
  }

  /// Icon for this store type
  IconData get icon {
    switch (this) {
      case StoreType.mega:
        return Icons.business_rounded;
      case StoreType.market:
        return Icons.storefront_rounded;
      case StoreType.toGo:
        return Icons.store_rounded;
      case StoreType.xpress:
        return Icons.flash_on_rounded;
    }
  }

  /// Asset path for map marker
  String get markerAssetPath {
    switch (this) {
      case StoreType.mega:
        return 'assets/icons/map_markers/MEGA.svg';
      case StoreType.market:
        return 'assets/icons/map_markers/MARKET.svg';
      case StoreType.toGo:
        return 'assets/icons/map_markers/toGO.svg';
      case StoreType.xpress:
        return 'assets/icons/map_markers/XPRESS.svg';
    }
  }
}
