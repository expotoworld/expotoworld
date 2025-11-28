import 'package:flutter/foundation.dart';
import '../../core/enums/store_type.dart';

class Store {
  final String id;
  final String name;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final StoreType type;
  final bool isActive;
  final String? etwStoreType;    // ETW store type (ETWMega, ETWMarket, ETWtoGO, ETWXpress)
  final String? etwMiniAppType;  // ETW mini-app type (ETWtoB, ETWtoC, ETWtoU, ETWtoG)

  Store({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.isActive = true,
    this.etwStoreType,
    this.etwMiniAppType,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    // Get ETW types from API response
    final etwStoreType = json['etw_store_type'] as String?;
    final etwMiniAppType = json['etw_mini_app_type'] as String?;

    return Store(
      id: json['id'].toString(), // Convert int to string for compatibility
      name: json['name'],
      city: json['city'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      type: _parseStoreType(json['type'], etwStoreType),
      isActive: json['is_active'] ?? true,
      etwStoreType: etwStoreType,
      etwMiniAppType: etwMiniAppType,
    );
  }

  /// Parse store type from API response (ETW types only)
  static StoreType _parseStoreType(dynamic typeValue, String? etwStoreType) {
    // First, try to use ETW store type if available
    if (etwStoreType != null && etwStoreType.isNotEmpty) {
      try {
        return StoreTypeExtension.fromApiValue(etwStoreType);
      } catch (e) {
        debugPrint('DEBUG: Could not parse ETW store type: $etwStoreType');
      }
    }

    // Handle null or empty type
    if (typeValue == null || typeValue.toString().isEmpty) {
      debugPrint('DEBUG: Store type is null/empty, defaulting to etwMarket');
      return StoreType.etwMarket;
    }

    final typeString = typeValue.toString();

    // Try to parse as ETW API value
    try {
      return StoreTypeExtension.fromApiValue(typeString);
    } catch (e) {
      // Fallback: try to parse as enum name
      try {
        return StoreType.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == typeString.toLowerCase(),
        );
      } catch (e2) {
        debugPrint('DEBUG: Unknown store type: "$typeString", defaulting to etwMarket');
        return StoreType.etwMarket;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.apiValue,
      'is_active': isActive,
      'etw_store_type': etwStoreType,
      'etw_mini_app_type': etwMiniAppType,
    };
  }
}


