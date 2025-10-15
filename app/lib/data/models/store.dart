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

  Store({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.isActive = true,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'].toString(), // Convert int to string for compatibility
      name: json['name'],
      city: json['city'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      type: _parseStoreType(json['type']),
      isActive: json['is_active'] ?? true,
    );
  }

  /// Parse store type from API response
  /// Handles both Chinese values from API and enum names for backward compatibility
  static StoreType _parseStoreType(dynamic typeValue) {
    if (typeValue == null) {
      throw ArgumentError('Store type cannot be null');
    }

    final typeString = typeValue.toString();

    // First try to parse as Chinese value (from API)
    try {
      return StoreTypeExtension.fromChineseValue(typeString);
    } catch (e) {
      // If that fails, try to parse as enum name (backward compatibility)
      try {
        return StoreType.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == typeString.toLowerCase(),
        );
      } catch (e2) {
        // If both fail, log the error and throw with helpful message
        debugPrint('ERROR: Unknown store type: "$typeString". Expected Chinese values: 无人门店, 无人仓店, 展销商店, 展销商城');
        throw ArgumentError('Unknown store type: "$typeString"');
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
      'type': type.toString().split('.').last,
      'is_active': isActive,
    };
  }
}


