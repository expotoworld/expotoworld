import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';
import '../providers/mini_app_providers.dart';

/// Map screen for mini-apps showing only stores of the relevant type
/// Styled to match the super-app map screen
class MiniAppMapScreen extends ConsumerStatefulWidget {
  final MiniAppType miniAppType;

  const MiniAppMapScreen({
    super.key,
    required this.miniAppType,
  });

  @override
  ConsumerState<MiniAppMapScreen> createState() => _MiniAppMapScreenState();
}

class _MiniAppMapScreenState extends ConsumerState<MiniAppMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  String? _errorMessage;

  // Map loading state
  bool _mapCreated = false;
  bool _isMapReady = false;

  // Custom markers cache
  Map<StoreType, BitmapDescriptor> _customMarkerIcons = {};
  bool _markersLoaded = false;

  // Visible map bounds for dynamic store list
  LatLngBounds? _visibleBounds;

  // Default location - Lugano, Switzerland
  static const LatLng _defaultLocation = LatLng(46.0037, 8.9511);

  // Map Styles
  String? _darkMapStyle;
  String? _lightMapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyles();
    _loadCustomMarkers();
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
      _buildMarkers();
    }
  }

  /// Loads an SVG file and converts it to a BitmapDescriptor for map markers
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

  void _buildMarkers() {
    final stores = ref.read(miniAppStoresProvider(widget.miniAppType));
    
    setState(() {
      _markers = stores.map((store) {
        // Use custom marker if loaded, fallback to default with hue
        final BitmapDescriptor icon =
            _markersLoaded && _customMarkerIcons.containsKey(store.storeType)
            ? _customMarkerIcons[store.storeType]!
            : BitmapDescriptor.defaultMarkerWithHue(
                _getHueForStoreType(store.storeType),
              );

        return Marker(
          markerId: MarkerId(store.id),
          position: store.location,
          icon: icon,
          onTap: () => _showStoreDetails(store),
        );
      }).toSet();
    });
  }

  double _getHueForStoreType(StoreType storeType) {
    switch (storeType) {
      case StoreType.mega:
        return BitmapDescriptor.hueAzure;
      case StoreType.market:
        return BitmapDescriptor.hueGreen;
      case StoreType.toGo:
        return BitmapDescriptor.hueViolet;
      case StoreType.xpress:
        return BitmapDescriptor.hueYellow;
    }
  }

  void _showStoreDetails(MiniAppStore store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true, // Show above bottom navigation bar
      builder: (context) => _StoreDetailsSheet(
        store: store,
        miniAppType: widget.miniAppType,
        onSelectStore: () {
          // Set as selected store and navigate to home
          ref.read(selectedStoreProvider(widget.miniAppType).notifier).state = store;
          Navigator.pop(context);
          context.go('/mini-app/${widget.miniAppType.name}/home');
        },
        onGetDirections: () {
          Navigator.pop(context);
          _openInExternalMaps(store);
        },
      ),
    );
  }

  /// Opens the store location in the native maps app
  Future<void> _openInExternalMaps(MiniAppStore store) async {
    final lat = store.location.latitude;
    final lng = store.location.longitude;
    final label = Uri.encodeComponent(store.name);

    Uri? mapUri;

    if (Platform.isIOS) {
      mapUri = Uri.parse('https://maps.apple.com/?q=$label&ll=$lat,$lng&z=17');
    } else if (Platform.isAndroid) {
      mapUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    } else {
      mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    }

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
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
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
        if (mounted) setState(() => _isMapReady = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'mapCouldNotGetLocation';
          _isMapReady = true;
        });
      }
    }
  }

  /// Called when map camera stops moving - updates visible bounds
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

  /// Returns stores that are within the visible map bounds
  List<MiniAppStore> _getVisibleStores() {
    final stores = ref.read(miniAppStoresProvider(widget.miniAppType));
    if (_visibleBounds == null) return stores;

    return stores.where((store) {
      final lat = store.location.latitude;
      final lng = store.location.longitude;
      return lat >= _visibleBounds!.southwest.latitude &&
          lat <= _visibleBounds!.northeast.latitude &&
          lng >= _visibleBounds!.southwest.longitude &&
          lng <= _visibleBounds!.northeast.longitude;
    }).toList();
  }

  /// Centers the map on a specific store location
  Future<void> _centerOnStore(MiniAppStore store) async {
    if (_mapController.isCompleted) {
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(store.location, 16),
      );
    }
  }

  /// Returns localized error message
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stores = ref.watch(miniAppStoresProvider(widget.miniAppType));
    final selectedStore = ref.watch(selectedStoreProvider(widget.miniAppType));
    final visibleStores = _getVisibleStores();

    // Return content directly without nested Scaffold
    // MiniAppShell provides the outer Scaffold with bottomNavigationBar
    // This ensures modal sheets appear above the bottom nav bar
    return Container(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Stack(
        children: [
          // 1. Google Map (full screen)
          AnimatedOpacity(
            opacity: _isMapReady ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: selectedStore?.location ?? _defaultLocation,
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
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              style: isDark ? _darkMapStyle : _lightMapStyle,
              markers: _markers,
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

          // 3. Top gradient overlay
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

          // 4. Nearby Stores horizontal list at bottom
          _buildNearbyStoresSheet(context, isDark, visibleStores),

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

          // 6. Location button + Store list button (top-right)
          Positioned(
            right: AppSpacing.lg,
            top: statusBarHeight + 16,
            child: Column(
              children: [
                _buildLocationButton(context, isDark),
                const SizedBox(height: 12),
                _buildStoreListButton(context, isDark, stores),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildStoreListButton(BuildContext context, bool isDark, List<MiniAppStore> stores) {
    return GestureDetector(
      onTap: () => _showStoreList(stores),
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
            Icons.list_rounded,
            color: AppColors.foregroundMuted(context),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyStoresSheet(BuildContext context, bool isDark, List<MiniAppStore> visibleStores) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Don't show if no stores
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
                  _centerOnStore(visibleStores[index]);
                  _showStoreDetails(visibleStores[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoreList(List<MiniAppStore> stores) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true, // Show above bottom navigation bar
      builder: (context) => _StoreListSheet(
        stores: stores,
        onStoreTap: (store) {
          Navigator.pop(context);
          _centerOnStore(store);
          _showStoreDetails(store);
        },
      ),
    );
  }
}

/// Horizontal store card matching super-app style
class _StoreCard extends StatelessWidget {
  final MiniAppStore store;
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
            // Left side: Store image placeholder
            Container(
              width: 90,
              height: 110,
              decoration: BoxDecoration(
                color: store.storeType.color.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: Center(
                child: Icon(
                  store.storeType.icon,
                  size: 40,
                  color: store.storeType.color,
                ),
              ),
            ),

            // Right side: Store info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store name
                    Expanded(
                      child: Text(
                        store.name,
                        style: AppTypography.labelMediumStyle.copyWith(
                          color: AppColors.foreground(context),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
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
                              color: store.storeType.color,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              store.formattedDistance,
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
                            color: store.storeType.color,
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
/// Store details bottom sheet matching super-app style
class _StoreDetailsSheet extends StatefulWidget {
  final MiniAppStore store;
  final MiniAppType miniAppType;
  final VoidCallback onSelectStore;
  final VoidCallback onGetDirections;

  const _StoreDetailsSheet({
    required this.store,
    required this.miniAppType,
    required this.onSelectStore,
    required this.onGetDirections,
  });

  @override
  State<_StoreDetailsSheet> createState() => _StoreDetailsSheetState();
}

class _StoreDetailsSheetState extends State<_StoreDetailsSheet> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

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
                  color: widget.store.storeType.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  widget.store.storeType.icon,
                  size: 44,
                  color: widget.store.storeType.color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store name FIRST
                    Text(
                      widget.store.name,
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
                        color: widget.store.storeType.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.store.storeType.displayName,
                        style: AppTypography.caption(
                          color: widget.store.storeType == StoreType.xpress
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

          // Address
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
                  widget.store.address,
                  style: AppTypography.bodySmall(
                    color: AppColors.foregroundMuted(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Distance
          Row(
            children: [
              Icon(
                Icons.near_me_rounded,
                size: 18,
                color: widget.store.storeType.color,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.mapAway(widget.store.formattedDistance),
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
              // Get Directions button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: widget.onGetDirections,
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: Text(l10n.mapDirections),
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
              // Shop Here button (highlighted with store color)
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: widget.onSelectStore,
                  icon: const Icon(Icons.shopping_bag_rounded, size: 20),
                  label: Text(l10n.mapVisitStore),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.store.storeType.color,
                    foregroundColor: widget.store.storeType == StoreType.xpress
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
              // Favorite heart button
              GestureDetector(
                onTap: () {
                  setState(() {
                    isFavorite = !isFavorite;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
                            ? 'Added to favorites'
                            : 'Removed from favorites',
                      ),
                      backgroundColor: widget.store.storeType.color,
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
  }
}

/// Store list bottom sheet
class _StoreListSheet extends StatelessWidget {
  final List<MiniAppStore> stores;
  final ValueChanged<MiniAppStore> onStoreTap;

  const _StoreListSheet({
    required this.stores,
    required this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'All Stores',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.foreground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${stores.length} nearby',
                  style: AppTypography.caption(
                    color: AppColors.foregroundMuted(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Store list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: bottomPadding + AppSpacing.md,
              ),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return _StoreListItem(
                  store: store,
                  onTap: () => onStoreTap(store),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual store list item
class _StoreListItem extends StatelessWidget {
  final MiniAppStore store;
  final VoidCallback onTap;

  const _StoreListItem({
    required this.store,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            // Store type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: store.storeType.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                store.storeType.icon,
                color: store.storeType.color,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            
            // Store info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: AppTypography.labelMediumStyle.copyWith(
                      color: AppColors.foreground(context),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.address,
                    style: AppTypography.caption(
                      color: AppColors.foregroundMuted(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Distance
            Text(
              store.formattedDistance,
              style: AppTypography.labelSmallStyle.copyWith(
                color: AppColors.foregroundMuted(context),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.foregroundMuted(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
