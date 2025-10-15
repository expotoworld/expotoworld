import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/store.dart';
import 'api_service.dart';
import '../../core/enums/store_type.dart';

class LocationService {
  static Position? _currentPosition;
  static String? _currentCity;
  static bool _locationPermissionGranted = false;

  // Get current location permission status with comprehensive debugging
  static Future<bool> hasLocationPermission() async {
    try {
      // Check multiple permission methods
      final permissionHandler = await Permission.locationWhenInUse.status;
      final geolocatorPermission = await Geolocator.checkPermission();
      final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

      debugPrint('=== PERMISSION DEBUG ===');
      debugPrint('Permission Handler status: $permissionHandler');
      debugPrint('Geolocator permission: $geolocatorPermission');
      debugPrint('Location service enabled: $locationServiceEnabled');
      debugPrint('========================');

      // Use Geolocator as primary check since it's more reliable for location
      final hasPermission = geolocatorPermission == LocationPermission.always ||
                           geolocatorPermission == LocationPermission.whileInUse;

      debugPrint('Final permission result: $hasPermission');
      return hasPermission && locationServiceEnabled;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  // Request location permission with multiple methods
  static Future<bool> requestLocationPermission() async {
    try {
      debugPrint('=== REQUESTING PERMISSION ===');

      // First check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('Location service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return false;
      }

      // Check current permission with Geolocator
      var geoPermission = await Geolocator.checkPermission();
      debugPrint('Current Geolocator permission: $geoPermission');

      if (geoPermission == LocationPermission.denied) {
        debugPrint('Requesting permission via Geolocator...');
        geoPermission = await Geolocator.requestPermission();
        debugPrint('Geolocator permission result: $geoPermission');
      }

      // Also try permission_handler as backup
      final permissionHandler = await Permission.locationWhenInUse.request();
      debugPrint('Permission Handler result: $permissionHandler');

      final hasPermission = geoPermission == LocationPermission.always ||
                           geoPermission == LocationPermission.whileInUse;

      debugPrint('Final permission granted: $hasPermission');
      debugPrint('=============================');

      _locationPermissionGranted = hasPermission;
      return hasPermission;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      if (!await isLocationServiceEnabled()) {
        debugPrint('Location services are disabled');
        throw Exception('Location services are disabled');
      }

      // Check permissions
      if (!await hasLocationPermission()) {
        debugPrint('No location permission, requesting...');
        final granted = await requestLocationPermission();
        if (!granted) {
          debugPrint('Location permission denied by user');
          throw Exception('Location permission denied');
        }
      }

      debugPrint('Getting current position...');
      // Get current position with increased timeout and fallback accuracy
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30), // Increased timeout to 30 seconds
        );
      } catch (e) {
        debugPrint('High accuracy failed, trying medium accuracy: $e');
        // Fallback to medium accuracy if high accuracy fails
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 20), // Shorter timeout for fallback
        );
      }

      debugPrint('Got position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  // Get current city from coordinates with Chinese localization
  static Future<String?> getCurrentCity() async {
    try {
      final position = _currentPosition ?? await getCurrentPosition();
      if (position == null) {
        debugPrint('getCurrentCity: No position available');
        return null;
      }

      debugPrint('getCurrentCity: Getting city for coordinates ${position.latitude}, ${position.longitude}');

      // Set Chinese locale for geocoding to get Chinese city names
      await setLocaleIdentifier('zh_CN');

      // Use geocoding to get Chinese city names
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        debugPrint('getCurrentCity: Placemark found - locality: ${placemark.locality}, administrativeArea: ${placemark.administrativeArea}, subAdministrativeArea: ${placemark.subAdministrativeArea}');

        // Try different fields to get the best city name
        String? cityName = placemark.locality ??
                          placemark.subAdministrativeArea ??
                          placemark.administrativeArea ??
                          placemark.subLocality;

        if (cityName != null && cityName.isNotEmpty) {
          _currentCity = cityName;
          debugPrint('getCurrentCity: Successfully got Chinese city name: $_currentCity');
          return _currentCity;
        } else {
          debugPrint('getCurrentCity: No valid city name found in placemark');
        }
      } else {
        debugPrint('getCurrentCity: No placemarks found for coordinates');
      }
    } catch (e) {
      debugPrint('Error getting current city: $e');
    }
    return null;
  }

  // Calculate distance between two points in kilometers
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  // Get nearest unmanned store to current location
  static Future<Store?> getNearestUnmannedStore() async {
    try {
      final position = _currentPosition ?? await getCurrentPosition();
      if (position == null) return null;

      final apiService = ApiService();
      final allStores = await apiService.fetchStores();
      final unmannedStores = allStores
          .where((store) => store.type == StoreType.unmannedStore || store.type == StoreType.unmannedWarehouse)
          .toList();

      if (unmannedStores.isEmpty) return null;

      Store? nearestStore;
      double minDistance = double.infinity;

      for (final store in unmannedStores) {
        final distance = calculateDistance(
          position.latitude,
          position.longitude,
          store.latitude,
          store.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestStore = store;
        }
      }

      return nearestStore;
    } catch (e) {
      debugPrint('Error getting nearest unmanned store: $e');
      return null;
    }
  }

  // Get all unmanned stores with distances
  static Future<List<StoreWithDistance>> getUnmannedStoresWithDistance() async {
    try {
      final position = _currentPosition ?? await getCurrentPosition();
      if (position == null) return [];

      final apiService = ApiService();
      final allStores = await apiService.fetchStores();
      final unmannedStores = allStores
          .where((store) => store.type == StoreType.unmannedStore || store.type == StoreType.unmannedWarehouse)
          .toList();

      final storesWithDistance = <StoreWithDistance>[];

      for (final store in unmannedStores) {
        final distance = calculateDistance(
          position.latitude,
          position.longitude,
          store.latitude,
          store.longitude,
        );

        storesWithDistance.add(StoreWithDistance(
          store: store,
          distance: distance,
        ));
      }

      // Sort by distance
      storesWithDistance.sort((a, b) => a.distance.compareTo(b.distance));

      return storesWithDistance;
    } catch (e) {
      debugPrint('Error getting unmanned stores with distance: $e');
      return [];
    }
  }

  // Calculate estimated walking time in minutes
  static int calculateWalkingTime(double distanceKm) {
    // Average walking speed: 5 km/h
    const walkingSpeedKmh = 5.0;
    final timeHours = distanceKm / walkingSpeedKmh;
    return (timeHours * 60).round(); // Convert to minutes
  }

  // Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
  }

  // Format walking time for display
  static String formatWalkingTime(int minutes) {
    if (minutes < 60) {
      return '$minutes分钟步行';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours小时步行';
      } else {
        return '$hours小时$remainingMinutes分钟步行';
      }
    }
  }

  // Initialize location service
  static Future<void> initialize() async {
    try {
      await getCurrentPosition();
      await getCurrentCity();
    } catch (e) {
      debugPrint('Error initializing location service: $e');
    }
  }

  // Get cached position (if available)
  static Position? get cachedPosition => _currentPosition;

  // Get cached city (if available)
  static String? get cachedCity => _currentCity;

  // Check if location permission is granted
  static bool get isLocationPermissionGranted => _locationPermissionGranted;
}

// Helper class to store store with distance
class StoreWithDistance {
  final Store store;
  final double distance;

  StoreWithDistance({
    required this.store,
    required this.distance,
  });

  String get formattedDistance => LocationService.formatDistance(distance);
  
  int get walkingTimeMinutes => LocationService.calculateWalkingTime(distance);
  
  String get formattedWalkingTime => LocationService.formatWalkingTime(walkingTimeMinutes);
}
