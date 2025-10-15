import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/store.dart';
import '../../data/services/location_service.dart';
import '../../data/services/storage_service.dart';

class LocationProvider extends ChangeNotifier with WidgetsBindingObserver {
  Position? _currentPosition;
  String? _currentCity;
  Store? _nearestStore;
  List<StoreWithDistance> _storesWithDistance = [];
  bool _isLoading = false;
  bool _hasLocationPermission = false;
  String? _errorMessage;

  // Constructor - automatically initialize location services and add lifecycle observer
  LocationProvider() {
    WidgetsBinding.instance.addObserver(this);
    _autoInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('LocationProvider: App resumed, refreshing location...');
      // Automatically refresh location when app resumes from background
      _refreshLocationOnResume();
    }
  }

  // Refresh location when app resumes (non-blocking)
  void _refreshLocationOnResume() {
    // Use a small delay to ensure the app is fully resumed
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_hasLocationPermission) {
        debugPrint('LocationProvider: Auto-refreshing location on app resume...');
        _updateLocation().catchError((error) {
          debugPrint('Auto-refresh failed: $error');
          // Silently fail - no user-visible errors for automatic refresh
        });
      }
    });
  }

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentCity => _currentCity;
  Store? get nearestStore => _nearestStore;
  List<StoreWithDistance> get storesWithDistance => _storesWithDistance;
  bool get isLoading => _isLoading;
  bool get hasLocationPermission => _hasLocationPermission;
  String? get errorMessage => _errorMessage;

  // Display city with fallback
  String get displayCity => _currentCity ?? '卢加诺';

  // Display store name with fallback
  String get displayStoreName => _nearestStore?.name ?? 'Via Nassa 店';

  // Automatically initialize location services (called from constructor)
  void _autoInitialize() {
    // Use a small delay to ensure the widget tree is built
    Future.delayed(const Duration(milliseconds: 500), () {
      initialize().catchError((error) {
        debugPrint('Auto-initialization failed: $error');
        // Silently fail and use fallback values - no user-visible errors
      });
    });
  }

  // Initialize location services with automatic permission request
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('LocationProvider: Initializing location services...');
      // Check current permission status first
      _hasLocationPermission = await LocationService.hasLocationPermission();
      debugPrint('LocationProvider: Current permission status: $_hasLocationPermission');

      if (_hasLocationPermission) {
        debugPrint('LocationProvider: Permission already granted, updating location...');
        await _updateLocation();
      } else {
        debugPrint('LocationProvider: No permission, automatically requesting...');
        // Automatically request location permission on app launch
        final granted = await LocationService.requestLocationPermission();
        debugPrint('LocationProvider: Auto permission request result: $granted');

        if (granted) {
          _hasLocationPermission = true;
          debugPrint('LocationProvider: Permission granted, updating location...');
          await _updateLocation();
        } else {
          debugPrint('LocationProvider: Permission denied, using fallback values');
          // Use fallback values when permission is denied
          _currentCity = '卢加诺';
          // Try to load saved main store even without location permission
          _nearestStore = await StorageService.loadMainStore();
        }
      }
    } catch (e) {
      debugPrint('Location initialization failed: $e');
      // Use fallback values on any error
      _currentCity = '卢加诺';
      _nearestStore = await StorageService.loadMainStore();
    } finally {
      _setLoading(false);
    }
  }

  // Update current location and related data
  Future<void> updateLocation() async {
    if (!_hasLocationPermission) {
      await initialize();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _updateLocation();
    } catch (e) {
      _setError('Failed to update location: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Private method to update location data
  Future<void> _updateLocation() async {
    // Get current position
    _currentPosition = await LocationService.getCurrentPosition();

    if (_currentPosition != null) {
      debugPrint('Location updated: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      // Get current city with explicit coordinates
      final newCity = await LocationService.getCurrentCity();
      if (newCity != null && newCity.isNotEmpty) {
        _currentCity = newCity;
        debugPrint('City updated successfully: $_currentCity');
      } else {
        debugPrint('Failed to get city name, keeping current: $_currentCity');
      }

      // Check if user has a saved main store, otherwise get nearest
      final savedMainStore = await StorageService.loadMainStore();
      if (savedMainStore != null) {
        _nearestStore = savedMainStore;
        debugPrint('Using saved main store: ${_nearestStore?.name}');
      } else {
        _nearestStore = await LocationService.getNearestUnmannedStore();
        debugPrint('Using nearest store: ${_nearestStore?.name}');
      }

      // Get all unmanned stores with distances
      _storesWithDistance = await LocationService.getUnmannedStoresWithDistance();

      // Notify listeners after all updates
      notifyListeners();
    } else {
      debugPrint('Failed to get current position');
    }
  }

  // Refresh location data
  Future<void> refresh() async {
    await updateLocation();
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('LocationProvider: Requesting location permission...');
      _hasLocationPermission = await LocationService.requestLocationPermission();
      debugPrint('LocationProvider: Permission result: $_hasLocationPermission');

      if (_hasLocationPermission) {
        debugPrint('LocationProvider: Permission granted, updating location...');
        await _updateLocation();
      } else {
        debugPrint('LocationProvider: Permission denied');
        _setError('Location permission is required for location features.');
      }

      return _hasLocationPermission;
    } catch (e) {
      debugPrint('LocationProvider: Error requesting permission: $e');
      _setError('Failed to request location permission: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Calculate distance to a specific store
  double? getDistanceToStore(Store store) {
    if (_currentPosition == null) return null;
    
    return LocationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      store.latitude,
      store.longitude,
    );
  }

  // Get formatted distance to a store
  String? getFormattedDistanceToStore(Store store) {
    final distance = getDistanceToStore(store);
    if (distance == null) return null;
    
    return LocationService.formatDistance(distance);
  }

  // Get walking time to a store
  int? getWalkingTimeToStore(Store store) {
    final distance = getDistanceToStore(store);
    if (distance == null) return null;
    
    return LocationService.calculateWalkingTime(distance);
  }

  // Get formatted walking time to a store
  String? getFormattedWalkingTimeToStore(Store store) {
    final walkingTime = getWalkingTimeToStore(store);
    if (walkingTime == null) return null;
    
    return LocationService.formatWalkingTime(walkingTime);
  }

  // Check if location services are available
  bool get isLocationAvailable => _currentPosition != null && _hasLocationPermission;

  // Set main store for order pickup
  void setMainStore(Store store) async {
    _nearestStore = store;

    // Save to persistent storage
    await StorageService.saveMainStore(store);

    notifyListeners();
  }

  // Force refresh location data and permissions
  Future<void> forceRefresh() async {
    _setLoading(true);
    try {
      debugPrint('LocationProvider: Force refreshing all data...');

      // Clear cached data
      _currentPosition = null;
      _currentCity = null;
      _nearestStore = null;
      _hasLocationPermission = false;
      _clearError();

      // Re-check permissions from scratch
      _hasLocationPermission = await LocationService.hasLocationPermission();
      debugPrint('LocationProvider: Force refresh permission result: $_hasLocationPermission');

      if (_hasLocationPermission) {
        await _updateLocation();
      } else {
        _currentCity = '卢加诺';
        _nearestStore = await StorageService.loadMainStore();
      }
    } catch (e) {
      debugPrint('Error force refreshing location: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Force permission re-check (for debugging)
  Future<void> debugPermissionCheck() async {
    debugPrint('=== MANUAL PERMISSION DEBUG ===');
    final hasPermission = await LocationService.hasLocationPermission();
    debugPrint('Manual permission check result: $hasPermission');
    _hasLocationPermission = hasPermission;
    notifyListeners();
    debugPrint('===============================');
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
