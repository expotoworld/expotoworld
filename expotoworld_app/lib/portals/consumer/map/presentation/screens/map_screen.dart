import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  String? _errorMessage;

  // Search state
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  AnimationController? _searchAnimationController;
  Animation<double>? _searchWidthAnimation;
  String _searchQuery = ''; // Current search query for filtering stores

  // Map Loading State
  bool _mapCreated = false;
  bool _isMapReady = false;

  // Custom markers cache
  Map<StoreType, BitmapDescriptor> _customMarkerIcons = {};
  bool _markersLoaded = false;

  // Visible map bounds for dynamic store list
  LatLngBounds? _visibleBounds;

  // Store type visibility filter (legend toggle)
  final Set<StoreType> _visibleStoreTypes = Set.from(StoreType.values);
  bool _isLegendExpanded = false;

  // Default location - Lugano, Switzerland
  static const LatLng _defaultLocation = LatLng(46.0037, 8.9511);

  // Map Styles
  String? _darkMapStyle;
  String? _lightMapStyle;

  @override
  void initState() {
    super.initState();
    _initSearchAnimation();
    _loadMapStyles();
    _loadCustomMarkers();
  }

  void _initSearchAnimation() {
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchWidthAnimation = CurvedAnimation(
      parent: _searchAnimationController!,
      curve: Curves.easeOutCubic,
    );
    
    // Listen to search input changes
    _searchController.addListener(_onSearchChanged);
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchAnimationController?.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
    });
    if (_isSearchExpanded) {
      _searchAnimationController?.forward();
      // Auto-focus the search field when expanding
      _searchFocusNode.requestFocus();
    } else {
      _searchAnimationController?.reverse();
      _searchController.clear();
      _searchFocusNode.unfocus();
    }
  }

  /// Returns localized error message for the given error key
  String _getLocalizedErrorMessage(BuildContext context, String errorKey) {
    final l10n = AppLocalizations.of(context)!;
    return switch (errorKey) {
      'mapLocationServicesDisabled' => l10n.mapLocationServicesDisabled,
      'mapLocationPermissionDenied' => l10n.mapLocationPermissionDenied,
      'mapLocationPermanentlyDenied' => l10n.mapLocationPermanentlyDenied,
      'mapCouldNotGetLocation' => l10n.mapCouldNotGetLocation,
      _ => errorKey,
    };
  }

  /// Closes the search bar and legend panel when tapping outside
  void _closeOverlays() {
    bool shouldUpdate = false;
    
    if (_isSearchExpanded) {
      _searchAnimationController?.reverse();
      _searchController.clear();
      _searchFocusNode.unfocus();
      _isSearchExpanded = false;
      shouldUpdate = true;
    }
    
    if (_isLegendExpanded) {
      _isLegendExpanded = false;
      shouldUpdate = true;
    }
    
    if (shouldUpdate) {
      setState(() {});
    }
  }

  Future<void> _loadMapStyles() async {
    _darkMapStyle = '''
    [
      {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
      {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
      {"featureType": "landscape.man_made", "elementType": "geometry.stroke", "stylers": [{"color": "#334e87"}]},
      {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#023e58"}]},
      {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
      {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
      {"featureType": "poi", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
      {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#023e58"}]},
      {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#3C7680"}]},
      {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
      {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
      {"featureType": "road", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
      {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
      {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#255763"}]},
      {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#b0d5ce"}]},
      {"featureType": "road.highway", "elementType": "labels.text.stroke", "stylers": [{"color": "#023e58"}]},
      {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
      {"featureType": "transit", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]}
    ]
    ''';

    _lightMapStyle = '''
    [
      {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
      {"featureType": "transit", "elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
      {"featureType": "water", "elementType": "geometry.fill", "stylers": [{"color": "#c9e4f5"}]}
    ]
    ''';
  }

  /// Loads custom marker icons from SVG assets for each store type
  Future<void> _loadCustomMarkers() async {
    final markers = <StoreType, BitmapDescriptor>{};

    for (final storeType in StoreType.values) {
      final icon = await _loadSvgMarkerIcon(storeType.markerAssetPath);
      markers[storeType] = icon;
    }

    if (mounted) {
      setState(() {
        _customMarkerIcons = markers;
        _markersLoaded = true;
      });
    }
  }

  /// Loads an SVG file and converts it to a BitmapDescriptor for map markers
  /// The marker size is optimized for mobile map display with HiDPI support
  Future<BitmapDescriptor> _loadSvgMarkerIcon(String assetPath) async {
    // Target height for the marker on the map (logical pixels)
    const double targetHeight = 60.0;
    // SVG original aspect ratio is 145.9 x 208.39 ≈ 0.7
    const double aspectRatio = 145.9 / 208.39;
    final double targetWidth = targetHeight * aspectRatio;
    
    // Use 3x scale for high DPI displays (covers most modern devices)
    const double devicePixelRatio = 3.0;
    final int renderWidth = (targetWidth * devicePixelRatio).ceil();
    final int renderHeight = (targetHeight * devicePixelRatio).ceil();

    try {
      // Load SVG string from assets
      final String svgString = await rootBundle.loadString(assetPath);

      // Create a PictureInfo from the SVG
      final PictureInfo pictureInfo = await vg.loadPicture(
        SvgStringLoader(svgString),
        null,
      );

      // Get the picture and calculate scaling
      final ui.Picture picture = pictureInfo.picture;
      final double scaleX = renderWidth / pictureInfo.size.width;
      final double scaleY = renderHeight / pictureInfo.size.height;
      final double scale = scaleX < scaleY ? scaleX : scaleY;

      // Create a new picture recorder to draw the scaled image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Scale the canvas
      canvas.scale(scale, scale);

      // Draw the SVG picture
      canvas.drawPicture(picture);

      // End recording and create image at high resolution
      final ui.Picture scaledPicture = recorder.endRecording();
      final ui.Image image = await scaledPicture.toImage(
        renderWidth,
        renderHeight,
      );

      // Convert to bytes
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      pictureInfo.picture.dispose();

      if (byteData == null) {
        return BitmapDescriptor.defaultMarker;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();
      // Use fromBytes with size hint for proper scaling on device
      return BitmapDescriptor.bytes(
        bytes,
        width: targetWidth,
        height: targetHeight,
      );
    } catch (e) {
      debugPrint('Error loading SVG marker from $assetPath: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _errorMessage = 'mapLocationServicesDisabled';
            _isMapReady = true;
          });
        }
        // Still show map with at least one store
        await _showDefaultViewWithStore();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _errorMessage = 'mapLocationPermissionDenied';
              _isMapReady = true;
            });
          }
          // Still show map with at least one store
          await _showDefaultViewWithStore();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _errorMessage = 'mapLocationPermanentlyDenied';
            _isMapReady = true;
          });
        }
        // Still show map with at least one store
        await _showDefaultViewWithStore();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        final userLocation = LatLng(position.latitude, position.longitude);
        
        // Find the nearest store to the user
        final nearestStore = _findNearestStore(userLocation);
        
        if (nearestStore != null) {
          // Calculate the distance to the nearest store (in meters)
          final distanceToStore = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            nearestStore.location.latitude,
            nearestStore.location.longitude,
          );
          
          // Calculate zoom level that keeps user centered but shows nearest store
          // The store needs to be in the viewport, so we need enough zoom-out
          // to cover at least the distance from user to store (plus some margin)
          // Map approximately covers 2x the visible radius on each side
          // So we need zoom level where visible radius > distance to store
          // 
          // Approximate visible radius at different zoom levels (meters):
          // Zoom 16: ~250m   | Zoom 15: ~500m   | Zoom 14: ~1km
          // Zoom 13: ~2km   | Zoom 12: ~4km   | Zoom 11: ~8km
          // Zoom 10: ~16km  | Zoom 9: ~32km   | Zoom 8: ~64km
          // Zoom 7: ~128km  | Zoom 6: ~256km  | Zoom 5: ~512km
          double zoom;
          if (distanceToStore <= 250) {
            zoom = 17.0;
          } else if (distanceToStore <= 500) {
            zoom = 16.0;
          } else if (distanceToStore <= 1000) {
            zoom = 15.0;
          } else if (distanceToStore <= 2000) {
            zoom = 14.0;
          } else if (distanceToStore <= 4000) {
            zoom = 13.0;
          } else if (distanceToStore <= 8000) {
            zoom = 12.0;
          } else if (distanceToStore <= 16000) {
            zoom = 11.0;
          } else if (distanceToStore <= 32000) {
            zoom = 10.0;
          } else if (distanceToStore <= 64000) {
            zoom = 9.0;
          } else if (distanceToStore <= 128000) {
            zoom = 8.0;
          } else if (distanceToStore <= 256000) {
            zoom = 7.0;
          } else {
            zoom = 6.0; // Very far - country/continent level
          }
          
          // Center on user with calculated zoom to show nearest store
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(userLocation, zoom),
          );
        } else {
          // Fallback: just center on user with default zoom
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(userLocation, 15),
          );
        }

        if (mounted) setState(() => _isMapReady = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'mapCouldNotGetLocation';
          _isMapReady = true;
        });
      }
      // Still show map with at least one store
      await _showDefaultViewWithStore();
    }
  }

  /// Shows a default view centered on the first store when user location is unavailable
  Future<void> _showDefaultViewWithStore() async {
    if (_mapController.isCompleted && _dummyStores.isNotEmpty) {
      final controller = await _mapController.future;
      final firstStore = _dummyStores.first;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(firstStore.location, 15),
      );
      if (mounted) setState(() => _isMapReady = true);
    }
  }

  /// Finds the nearest store to a given location
  Store? _findNearestStore(LatLng location) {
    if (_dummyStores.isEmpty) return null;
    
    Store? nearest;
    double minDistance = double.infinity;
    
    for (final store in _dummyStores) {
      final distance = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        store.location.latitude,
        store.location.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = store;
      }
    }
    return nearest;
  }

  /// Called when map camera stops moving - updates visible bounds for dynamic store list
  Future<void> _onCameraIdle() async {
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      final bounds = await controller.getVisibleRegion();
      if (mounted && bounds != _visibleBounds) {
        setState(() {
          _visibleBounds = bounds;
        });
      }
    }
  }

  /// Returns stores that are within the visible map bounds, have visible store types,
  /// and match the search query (if any)
  List<Store> _getVisibleStores() {
    // First filter by store type visibility (legend filter)
    var filtered = _dummyStores
        .where((store) => _visibleStoreTypes.contains(store.storeType))
        .toList();
    
    // Filter by search query (name or address)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((store) {
        final nameMatch = store.name.toLowerCase().contains(_searchQuery);
        final addressMatch = store.address?.toLowerCase().contains(_searchQuery) ?? false;
        final typeMatch = store.storeType.displayName.toLowerCase().contains(_searchQuery);
        return nameMatch || addressMatch || typeMatch;
      }).toList();
    }
    
    // Then filter by visible map bounds (only if no search query, to show all search results)
    if (_visibleBounds == null || _searchQuery.isNotEmpty) return filtered;

    return filtered.where((store) {
      final lat = store.location.latitude;
      final lng = store.location.longitude;
      return lat >= _visibleBounds!.southwest.latitude &&
          lat <= _visibleBounds!.northeast.latitude &&
          lng >= _visibleBounds!.southwest.longitude &&
          lng <= _visibleBounds!.northeast.longitude;
    }).toList();
  }

  /// Centers the map on a specific store location
  Future<void> _centerOnStore(Store store) async {
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(store.location, 16),
      );
    }
  }

  /// Opens the store location in the native maps app
  /// Detects platform and uses appropriate URL scheme:
  /// - iOS: Apple Maps (or Google Maps if installed)
  /// - Android: Google Maps
  /// - Others: Google Maps web
  Future<void> _openInExternalMaps(Store store) async {
    final lat = store.location.latitude;
    final lng = store.location.longitude;
    final label = Uri.encodeComponent(store.name);

    Uri? mapUri;

    if (Platform.isIOS) {
      // Try Apple Maps first on iOS
      mapUri = Uri.parse('https://maps.apple.com/?q=$label&ll=$lat,$lng&z=17');
    } else if (Platform.isAndroid) {
      // Use Google Maps geo intent on Android
      mapUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    } else {
      // Fallback to Google Maps web
      mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    }

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Google Maps web if native app fails
        final webUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        );
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.mapCouldNotOpen),
            backgroundColor: AppColors.themeRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Return content directly without nested Scaffold
    // MainShell provides the outer Scaffold with bottomNavigationBar
    // This ensures modal sheets appear above the bottom nav bar
    return Container(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Stack(
        children: [
          // 1. Google Map
          AnimatedOpacity(
            opacity: _isMapReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _defaultLocation,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController.complete(controller);
                if (!_mapCreated) {
                  _mapCreated = true;
                  _getCurrentLocation();
                }
              },
              onCameraIdle: _onCameraIdle,
              onTap: (_) => _closeOverlays(),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              style: isDark ? _darkMapStyle : _lightMapStyle,
              markers: _buildMarkers(),
            ),
          ),

          // 2. Loading Spinner
          if (!_isMapReady)
            Center(
              child: CircularProgressIndicator(
                color: AppColors.themeRed,
                strokeWidth: 3,
              ),
            ),

          // 3. Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: statusBarHeight + 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.black : Colors.white).withValues(
                      alpha: 0.8,
                    ),
                    (isDark ? Colors.black : Colors.white).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // 4. Stores Sheet
          _buildNearbyStoresSheet(context, isDark),

          // 5. Error Toast
          if (_errorMessage != null)
            Positioned(
              top: statusBarHeight + 20,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.themeRed.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _getLocalizedErrorMessage(context, _errorMessage!),
                        style: AppTypography.bodySmall(color: Colors.white),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _errorMessage = null);
                        _getCurrentLocation();
                      },
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 6. Location Button and Legend
          Positioned(
            right: AppSpacing.lg,
            top: statusBarHeight + 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildLocationButton(context, isDark),
                const SizedBox(height: 12),
                _buildLegendWidget(context, isDark),
              ],
            ),
          ),

          // 7. Search Bar
          Positioned(
            right: AppSpacing.lg,
            top: statusBarHeight + 16,
            child: _buildAnimatedSearchBar(context, isDark),
          ),
        ],
      ),
    );
  }

  /// Get marker hue from store type color
  double _getMarkerHue(StoreType storeType) {
    switch (storeType) {
      case StoreType.mega:
        return BitmapDescriptor.hueAzure; // Blue
      case StoreType.market:
        return BitmapDescriptor.hueGreen; // Green
      case StoreType.toGo:
        return BitmapDescriptor.hueViolet; // Purple
      case StoreType.xpress:
        return BitmapDescriptor.hueYellow; // Yellow
    }
  }

  Set<Marker> _buildMarkers() {
    // Apply the same filters as visible stores (type + search query)
    var stores = _dummyStores
        .where((store) => _visibleStoreTypes.contains(store.storeType));
    
    // Filter by search query if present
    if (_searchQuery.isNotEmpty) {
      stores = stores.where((store) {
        final nameMatch = store.name.toLowerCase().contains(_searchQuery);
        final addressMatch = store.address?.toLowerCase().contains(_searchQuery) ?? false;
        final typeMatch = store.storeType.displayName.toLowerCase().contains(_searchQuery);
        return nameMatch || addressMatch || typeMatch;
      });
    }
    
    return stores.map((store) {
      // Use custom marker if loaded, fallback to default with hue
      final BitmapDescriptor icon =
          _markersLoaded && _customMarkerIcons.containsKey(store.storeType)
          ? _customMarkerIcons[store.storeType]!
          : BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerHue(store.storeType),
            );

      return Marker(
        markerId: MarkerId(store.name),
        position: store.location,
        icon: icon,
        onTap: () => _showStoreDetailSheet(context, store),
        // InfoWindow is hidden - we use the custom bottom sheet popup instead
      );
    }).toSet();
  }

  Widget _buildLocationButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: _getCurrentLocation,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1C1C1E).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.my_location_rounded,
            color: AppColors.themeRed,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Builds the legend toggle widget for filtering store types on the map
  Widget _buildLegendWidget(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Toggle button (always visible, separate from panel)
        GestureDetector(
          onTap: () {
            setState(() {
              _isLegendExpanded = !_isLegendExpanded;
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.95),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Icon(
                _isLegendExpanded ? Icons.layers : Icons.layers_outlined,
                color: _isLegendExpanded 
                    ? AppColors.themeRed 
                    : AppColors.foregroundMuted(context),
                size: 24,
              ),
            ),
          ),
        ),
        // Expanded legend panel (separate box below button)
        if (_isLegendExpanded) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E).withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: StoreType.values.map((type) => _buildLegendItem(context, type, isDark)).toList(),
            ),
          ),
        ],
      ],
    );
  }

  /// Builds a single legend item for filtering a store type
  Widget _buildLegendItem(BuildContext context, StoreType type, bool isDark) {
    final isVisible = _visibleStoreTypes.contains(type);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isVisible) {
            _visibleStoreTypes.remove(type);
          } else {
            _visibleStoreTypes.add(type);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 100, // Fixed width for all items
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isVisible 
              ? type.color.withValues(alpha: 0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isVisible 
                ? type.color.withValues(alpha: 0.4) 
                : (isDark ? Colors.white12 : Colors.black12),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // SVG marker icon
            Opacity(
              opacity: isVisible ? 1.0 : 0.4,
              child: SvgPicture.asset(
                type.markerAssetPath,
                width: 16,
                height: 22,
              ),
            ),
            const SizedBox(width: 6),
            // Left-aligned text
            Expanded(
              child: Text(
                type.displayName,
                style: AppTypography.caption(
                  color: isVisible 
                      ? AppColors.foreground(context) 
                      : AppColors.foregroundMuted(context),
                ).copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSearchBar(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    const buttonSize = 48.0;
    const safeChildSize = 46.0;
    final expandedWidth = screenWidth - (AppSpacing.lg * 2);

    if (_searchWidthAnimation == null) {
      return _buildLocationButton(context, isDark);
    }

    return AnimatedBuilder(
      animation: _searchWidthAnimation!,
      builder: (context, child) {
        final animValue = _searchWidthAnimation!.value;
        final currentWidth =
            buttonSize + (animValue * (expandedWidth - buttonSize));
        final isExpanded = animValue > 0.05;

        return Container(
          width: currentWidth,
          height: buttonSize,
          // FIX 1: Enable clipping to force everything inside to be round
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            // Match location button background
            color: isDark
                ? const Color(0xFF1C1C1E).withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(buttonSize / 2),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // Search input field (visible when expanded)
              if (isExpanded)
                Expanded(
                  child: Opacity(
                    opacity: animValue,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 24, // Increased left padding to shift input right
                        right: AppSpacing.sm,
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textAlignVertical: TextAlignVertical.center,
                        style: AppTypography.bodyMedium(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.mapSearchHint,
                          hintStyle: AppTypography.bodyMedium(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.4),
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ),
                ),

              // Search/Close icon button with rotation animation
              GestureDetector(
                onTap: _toggleSearch,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: safeChildSize,
                  height: safeChildSize,
                  child: Center(
                    child: Padding(
                      // Slight optical adjustment for magnifying glass icon
                      padding: EdgeInsets.only(
                        left: _isSearchExpanded ? 0 : 1,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return RotationTransition(
                            turns: Tween(
                              begin: 0.25,
                              end: 0.0,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          _isSearchExpanded
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          key: ValueKey(_isSearchExpanded),
                          color: _isSearchExpanded
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.black.withValues(alpha: 0.6))
                              : AppColors.themeRed,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStoreDetailSheet(BuildContext context, Store store) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // State variable outside the builder to persist across rebuilds
    bool isFavorite = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true, // Show above bottom navigation bar
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.sm,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Store header with larger image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Larger store icon/image badge
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: store.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(store.icon, size: 44, color: store.color),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store name FIRST
                          Text(
                            store.name,
                            style: AppTypography.h4(
                              color: AppColors.foreground(context),
                            ).copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Store type pill BELOW the name
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: store.color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              store.storeType.displayName,
                              style: AppTypography.caption(
                                color: store.storeType == StoreType.xpress
                                    ? Colors.black87
                                    : Colors.white,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Address and distance
                if (store.address != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: AppColors.foregroundMuted(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          store.address!,
                          style: AppTypography.bodySmall(
                            color: AppColors.foregroundMuted(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.near_me_rounded, size: 18, color: store.color),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.mapAway(store.distance),
                      style: AppTypography.bodySmall(
                        color: AppColors.foreground(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Action buttons - One row: Get Directions + Visit Store + Favorite Heart
                Row(
                  children: [
                    // Get Directions button (opens native maps)
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openInExternalMaps(store);
                        },
                        icon: const Icon(Icons.directions_rounded, size: 18),
                        label: Text(AppLocalizations.of(context)!.mapDirections),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          foregroundColor: AppColors.foreground(context),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Visit Store button (highlighted with store color)
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Navigate to store's product page
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${AppLocalizations.of(context)!.mapVisiting} ${store.name}...'),
                              backgroundColor: store.color,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.storefront_rounded, size: 20),
                        label: Text(AppLocalizations.of(context)!.mapVisitStore),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: store.color,
                          foregroundColor: store.storeType == StoreType.xpress
                              ? Colors.black87
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Favorite heart button (rectangular)
                    GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          isFavorite = !isFavorite;
                        });
                        // TODO: Save favorite status to state management/backend
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavorite
                                  ? 'Added to favorites'
                                  : 'Removed from favorites',
                            ),
                            backgroundColor: store.color,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? AppColors.themeRed.withValues(alpha: 0.15)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFavorite
                                ? AppColors.themeRed.withValues(alpha: 0.3)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08)),
                          ),
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? AppColors.themeRed
                              : AppColors.foregroundMuted(context),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNearbyStoresSheet(BuildContext context, bool isDark) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final visibleStores = _getVisibleStores();
    
    // Don't show the sheet if no stores are visible
    if (visibleStores.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 25 + bottomPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Nearby Stores',
              style: AppTypography.h4(
                color: isDark ? Colors.white : Colors.black,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              scrollDirection: Axis.horizontal,
              itemCount: visibleStores.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) => _StoreCard(
                store: visibleStores[index],
                onTap: () {
                  // Close search if open when selecting a store
                  if (_isSearchExpanded) {
                    _closeOverlays();
                  }
                  _centerOnStore(visibleStores[index]);
                  _showStoreDetailSheet(context, visibleStores[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const _StoreCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        height: 110,
        decoration: BoxDecoration(
          // Solid background - not translucent
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left side: Store image placeholder (3/4 of card height)
            Container(
              width: 90,
              height: 110,
              decoration: BoxDecoration(
                color: store.color.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: Center(
                child: Icon(store.icon, size: 40, color: store.color),
              ),
            ),

            // Right side: Store info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store name (max 2 lines, ellipsis)
                    Expanded(
                      child: Text(
                        store.name,
                        style: AppTypography.labelMedium(
                          color: AppColors.foreground(context),
                        ).copyWith(fontWeight: FontWeight.w600, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Bottom row: Distance + Store type tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Distance
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me_rounded,
                              size: 12,
                              color: store.color,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              store.distance,
                              style: AppTypography.caption(
                                color: AppColors.foregroundMuted(context),
                              ),
                            ),
                          ],
                        ),

                        // Store type pill tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: store.color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            store.storeType.displayName,
                            style:
                                AppTypography.caption(
                                  color: store.storeType == StoreType.xpress
                                      ? Colors.black87
                                      : Colors.white,
                                ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Store type enum for categorization
enum StoreType {
  mega, // Royal Blue - B2B Exposition
  market, // Nature Green - B2C Marketplace
  toGo, // Vivid Purple - Automated Store
  xpress, // Radiant Yellow - Express Pickup
}

extension StoreTypeExtension on StoreType {
  /// Brand colors for each store type
  Color get color {
    switch (this) {
      case StoreType.mega:
        return const Color(0xFF0066CC); // Royal Blue
      case StoreType.market:
        return const Color(0xFF107C10); // Nature Green
      case StoreType.toGo:
        return const Color(0xFF6A1B9A); // Vivid Purple
      case StoreType.xpress:
        return const Color(0xFFFFC107); // Radiant Yellow
    }
  }

  /// Icons for each store type (Material Symbols)
  IconData get icon {
    switch (this) {
      case StoreType.mega:
        return Icons.store_rounded; // store
      case StoreType.market:
        return Icons.local_mall_rounded; // local_mall
      case StoreType.toGo:
        return Icons
            .shopping_cart_rounded; // trolley (shopping_cart as fallback)
      case StoreType.xpress:
        return Icons.shopping_basket_rounded; // shopping_basket
    }
  }

  /// Display name for each store type
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

  /// Subtitle for each store type
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

  /// Asset path for the custom map marker SVG icon
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

class Store {
  final String name;
  final StoreType storeType;
  final String distance;
  final double distanceMeters; // For sorting
  final LatLng location;
  final String? imageUrl; // For store image
  final String? address; // For detail sheet

  Store({
    required this.name,
    required this.storeType,
    required this.distance,
    required this.distanceMeters,
    required this.location,
    this.imageUrl,
    this.address,
  });

  Color get color => storeType.color;
  IconData get icon => storeType.icon;
  String get type => storeType.subtitle;
}

// Sorted by distance (closest first)
final List<Store> _dummyStores = [
  Store(
    name: 'MANOR Lugano Centro City Point',
    storeType: StoreType.toGo,
    distance: '0.8 km',
    distanceMeters: 800,
    location: const LatLng(46.0020, 8.9490),
    address: 'Via Nassa 5, 6900 Lugano, Switzerland',
  ),
  Store(
    name: 'EXPO XPRESS Stazione FFS',
    storeType: StoreType.xpress,
    distance: '1.5 km',
    distanceMeters: 1500,
    location: const LatLng(46.0060, 8.9470),
    address: 'Piazzale Stazione, 6900 Lugano, Switzerland',
  ),
  Store(
    name: 'EXPO MEGA Lugano Convention',
    storeType: StoreType.mega,
    distance: '2.3 km',
    distanceMeters: 2300,
    location: const LatLng(46.0050, 8.9530),
    address: 'Via Cantonale 12, 6900 Lugano, Switzerland',
  ),
  Store(
    name: 'EXPO MARKET Paradiso Lakeside',
    storeType: StoreType.market,
    distance: '3.1 km',
    distanceMeters: 3100,
    location: const LatLng(45.9940, 8.9450),
    address: 'Riva Paradiso 22, 6902 Paradiso, Switzerland',
  ),
];
