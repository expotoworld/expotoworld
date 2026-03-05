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
  final double distanceMeters; // Distance from user location
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

  /// Deserialize from backend `StoreResponse` JSON.
  ///
  /// Backend fields: store_id (int32), name, city, address, latitude,
  /// longitude, image_url, etw_store_type, is_active, created_at, updated_at.
  /// `distanceMeters` is calculated client-side and defaults to 0.
  factory MiniAppStore.fromJson(Map<String, dynamic> json) {
    return MiniAppStore(
      id: json['store_id'].toString(),
      name: json['name'] as String? ?? '',
      storeType:
          StoreTypeExtension.fromApiValue(json['etw_store_type'] as String?) ??
          StoreType.market,
      address: json['address'] as String? ?? json['city'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: 0, // Calculated client-side from user location
      imageUrl: json['image_url'] as String?,
    );
  }

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

  /// Create a copy with a different distance (for location-based sorting).
  MiniAppStore copyWithDistance(double distance) {
    return MiniAppStore(
      id: id,
      name: name,
      storeType: storeType,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distance,
      imageUrl: imageUrl,
    );
  }
}

/// Category model for product categories (brands)
class MiniAppCategory {
  final String id;
  final String name; // Brand name (e.g., "Barilla", "AXA")
  final String? iconUrl;
  final String? imageUrl; // Full image URL for the category
  final String? description;

  const MiniAppCategory({
    required this.id,
    required this.name,
    this.iconUrl,
    this.imageUrl,
    this.description,
  });

  /// Deserialize from backend `CategoryResponse` JSON.
  ///
  /// Backend fields: category_id, name, image_url, display_order,
  /// is_active, store_id, etw_store_type, etw_mini_app_type,
  /// subcategory_count, product_count, created_at, updated_at.
  factory MiniAppCategory.fromJson(Map<String, dynamic> json) {
    return MiniAppCategory(
      id: json['category_id'].toString(),
      name: json['name'] as String? ?? '',
      iconUrl: json['image_url'] as String?,
      imageUrl: json['image_url'] as String?,
      description: null, // Not returned by the backend
    );
  }
}

/// Subcategory model for product subcategories
class MiniAppSubcategory {
  final String id;
  final String name; // e.g., "Pasta", "Spaghetti", "Home Insurance"
  final String categoryId; // Parent category ID
  final String? iconUrl;
  final String? imageUrl; // Full image URL for the subcategory
  final String? description;
  final int productCount; // Number of products in this subcategory

  const MiniAppSubcategory({
    required this.id,
    required this.name,
    required this.categoryId,
    this.iconUrl,
    this.imageUrl,
    this.description,
    this.productCount = 0,
  });

  /// Deserialize from backend `SubcategoryResponse` JSON.
  ///
  /// Backend fields: subcategory_id, category_id, name, image_url,
  /// display_order, is_active, product_count, created_at, updated_at.
  factory MiniAppSubcategory.fromJson(Map<String, dynamic> json) {
    return MiniAppSubcategory(
      id: json['subcategory_id'].toString(),
      name: json['name'] as String? ?? '',
      categoryId: json['category_id'].toString(),
      iconUrl: json['image_url'] as String?,
      imageUrl: json['image_url'] as String?,
      description: null, // Not returned by the backend
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Collection model for product collections (3rd tier under subcategories)
class MiniAppCollection {
  final String id;
  final String name;
  final String subcategoryId; // Parent subcategory ID
  final String? imageUrl;
  final int productCount;

  const MiniAppCollection({
    required this.id,
    required this.name,
    required this.subcategoryId,
    this.imageUrl,
    this.productCount = 0,
  });

  /// Deserialize from backend `CollectionResponse` JSON.
  ///
  /// Backend fields: collection_id, subcategory_id, name, image_url,
  /// display_order, is_active, product_count, created_at, updated_at.
  factory MiniAppCollection.fromJson(Map<String, dynamic> json) {
    return MiniAppCollection(
      id: json['collection_id'].toString(),
      name: json['name'] as String? ?? '',
      subcategoryId: json['subcategory_id'].toString(),
      imageUrl: json['image_url'] as String?,
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Subcollection model for the optional 4th tier under collections.
class MiniAppSubcollection {
  final String id;
  final String name;
  final String collectionId; // Parent collection ID
  final String? imageUrl;
  final int productCount;

  const MiniAppSubcollection({
    required this.id,
    required this.name,
    required this.collectionId,
    this.imageUrl,
    this.productCount = 0,
  });

  /// Deserialize from backend `SubcollectionResponse` JSON.
  ///
  /// Backend fields: subcollection_id, collection_id, name, image_url,
  /// display_order, is_active, product_count, created_at, updated_at.
  factory MiniAppSubcollection.fromJson(Map<String, dynamic> json) {
    return MiniAppSubcollection(
      id: json['subcollection_id'].toString(),
      name: json['name'] as String? ?? '',
      collectionId: json['collection_id'].toString(),
      imageUrl: json['image_url'] as String?,
      productCount: (json['product_count'] as num?)?.toInt() ?? 0,
    );
  }
}
