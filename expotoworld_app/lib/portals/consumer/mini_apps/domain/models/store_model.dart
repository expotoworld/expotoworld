import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../enums/mini_app_type.dart';

/// Store model for mini-app stores
class MiniAppStore {
  final String id;
  final String name;
  final StoreType storeType;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceMeters;  // Distance from user location
  final String? imageUrl;

  const MiniAppStore({
    required this.id,
    required this.name,
    required this.storeType,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.imageUrl,
  });

  /// LatLng location for Google Maps
  LatLng get location => LatLng(latitude, longitude);

  /// Formatted distance string
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}

/// Category model for product categories (brands)
class MiniAppCategory {
  final String id;
  final String name;           // Brand name (e.g., "Barilla", "AXA")
  final String? iconUrl;
  final String? imageUrl;      // Full image URL for the category
  final String? description;

  const MiniAppCategory({
    required this.id,
    required this.name,
    this.iconUrl,
    this.imageUrl,
    this.description,
  });
}

/// Subcategory model for product subcategories
class MiniAppSubcategory {
  final String id;
  final String name;           // e.g., "Pasta", "Spaghetti", "Home Insurance"
  final String categoryId;     // Parent category ID
  final String? iconUrl;
  final String? imageUrl;      // Full image URL for the subcategory
  final String? description;
  final int productCount;      // Number of products in this subcategory

  const MiniAppSubcategory({
    required this.id,
    required this.name,
    required this.categoryId,
    this.iconUrl,
    this.imageUrl,
    this.description,
    this.productCount = 0,
  });
}
