import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/map_marker_utils.dart';
import '../../../data/models/store.dart';
import '../../../data/services/api_service.dart';
import '../../../core/enums/store_type.dart';
import '../../providers/location_provider.dart';


class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Store? _selectedStore;
  final ApiService _apiService = ApiService();
  List<Store> _allStores = [];
  List<Store> _filteredStores = [];

  // Legend filtering state - all store types visible by default
  final Map<StoreType, bool> _storeTypeVisibility = {
    StoreType.unmannedStore: true,
    StoreType.unmannedWarehouse: true,
    StoreType.exhibitionStore: true,
    StoreType.exhibitionMall: true,
  };

  // Cache for custom markers
  final Map<StoreType, BitmapDescriptor> _markerCache = {};

  @override
  void initState() {
    super.initState();
    _loadStores();
    _initializeMarkers();
  }

  void _initializeMarkers() async {
    // Pre-load standard markers for better performance
    for (final storeType in StoreType.values) {
      _markerCache[storeType] = await MapMarkerUtils.getStoreMarkerIcon(storeType);
    }
    if (mounted) setState(() {});
  }

  void _loadStores() async {
    try {
      final stores = await _apiService.fetchStores();
      setState(() {
        _allStores = stores;
        _filteredStores = stores;
      });
    } catch (e) {
      debugPrint('Error loading stores: $e');
    }
  }

  void _filterStores(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStores = _allStores;
      } else {
        _filteredStores = _allStores.where((store) {
          return store.name.toLowerCase().contains(query.toLowerCase()) ||
                 store.address.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          _buildFullScreenMap(),

          // NEW CORRECTED LAYOUT
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              // Use bottom: false because we only care about top padding here
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: Row(
                  // Align the top of the left-side controls and the top of the legend
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // This Expanded widget contains the search bar
                    Expanded(
                      child: Row(
                        children: [
                          // Search bar will be created in the next step
                          Expanded(child: _buildSearchBar()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // The legend sits here, and its height will not affect
                    // the vertical alignment of the back button and search bar.
                    _buildMapLegend(),
                  ],
                ),
              ),
            ),
          ),

          // My location button (positioned below legend)
          _buildLocationButton(),

          // Store details bottom sheet
          if (_selectedStore != null) _buildStoreDetailsSheet(),
        ],
      ),
    );
  }

  Widget _buildFullScreenMap() {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final userPosition = locationProvider.currentPosition;

        // Show loading indicator if stores are not loaded yet
        if (_filteredStores.isEmpty && _allStores.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.themeRed,
            ),
          );
        }

        // Use filtered stores for display
        final stores = _filteredStores;

        if (stores.isEmpty) {
          return const Center(
            child: Text('暂无门店数据'),
          );
        }

        // Create markers for all stores
        final Set<Marker> markers = {};

        // Add store markers with custom styling based on store type and visibility
        for (final store in stores) {
          // Only add marker if this store type is visible
          if (_storeTypeVisibility[store.type] == true) {
            final markerIcon = _markerCache[store.type];
            if (markerIcon != null) {
              markers.add(
                Marker(
                  markerId: MarkerId(store.id.toString()),
                  position: LatLng(store.latitude, store.longitude),
                  icon: markerIcon,
                  infoWindow: InfoWindow(
                    title: store.name,
                    snippet: store.address,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedStore = store;
                    });
                  },
                ),
              );
            }
          }
        }

        // Add user location marker if available
        // if (userPosition != null && _userLocationMarker != null) {
        //   markers.add(
        //     Marker(
        //       markerId: const MarkerId('user_location'),
        //       position: LatLng(userPosition.latitude, userPosition.longitude),
        //       icon: _userLocationMarker!,
        //       infoWindow: const InfoWindow(
        //         title: '我的位置',
        //         snippet: '当前位置',
        //       ),
        //     ),
        //   );
        // }

        return GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // Fit map to show all stores after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              _fitMapToStores(controller, stores, userPosition);
            });
          },
          initialCameraPosition: CameraPosition(
            target: userPosition != null
                ? LatLng(userPosition.latitude, userPosition.longitude)
                : stores.isNotEmpty
                    ? LatLng(stores.first.latitude, stores.first.longitude)
                    : const LatLng(46.0037, 8.9511), // Default to Switzerland center
            zoom: 12.0,
          ),
          markers: markers,
          myLocationEnabled: true, // We handle location manually
          myLocationButtonEnabled: false, // We have custom location button
          zoomControlsEnabled: true, // We have custom controls
          mapToolbarEnabled: false,
          onTap: (LatLng position) {
            // Hide store details when tapping on map
            if (_selectedStore != null) {
              setState(() {
                _selectedStore = null;
              });
            }
          },
          onCameraMove: (CameraPosition position) {
            // Optional: Handle camera movement for real-time updates
          },
        );
      },
    );
  }

  // Helper method to fit map bounds to show all stores
  void _fitMapToStores(GoogleMapController controller, List<Store> stores, Position? userPosition) {
    if (stores.isEmpty) return;

    double minLat = stores.first.latitude;
    double maxLat = stores.first.latitude;
    double minLng = stores.first.longitude;
    double maxLng = stores.first.longitude;

    // Find bounds of all stores
    for (final store in stores) {
      minLat = math.min(minLat, store.latitude);
      maxLat = math.max(maxLat, store.latitude);
      minLng = math.min(minLng, store.longitude);
      maxLng = math.max(maxLng, store.longitude);
    }

    // Include user position in bounds if available
    if (userPosition != null) {
      minLat = math.min(minLat, userPosition.latitude);
      maxLat = math.max(maxLat, userPosition.latitude);
      minLng = math.min(minLng, userPosition.longitude);
      maxLng = math.max(maxLng, userPosition.longitude);
    }

    // Add padding to bounds
    const padding = 0.01; // Roughly 1km
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    // Animate camera to fit bounds
    Future.delayed(const Duration(milliseconds: 500), () {
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0, // padding
        ),
      );
    });
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '店铺类型',
            style: AppTextStyles.cardTitle.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem('无人门店', MapMarkerUtils.unmannedStoreColor, StoreType.unmannedStore),
          _buildLegendItem('无人仓店', MapMarkerUtils.unmannedWarehouseColor, StoreType.unmannedWarehouse),
          _buildLegendItem('展销商店', MapMarkerUtils.exhibitionStoreColor, StoreType.exhibitionStore),
          _buildLegendItem('展销商城', MapMarkerUtils.exhibitionMallColor, StoreType.exhibitionMall),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, StoreType storeType) {
    final isVisible = _storeTypeVisibility[storeType] ?? true;

    return GestureDetector(
      onTap: () {
        setState(() {
          _storeTypeVisibility[storeType] = !isVisible;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isVisible ? color : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isVisible ? AppColors.secondaryText : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSearchBar() {
    return Container(
      height: 48, // A fixed height for alignment
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索店铺...',
          hintStyle: AppTextStyles.body.copyWith(
            color: AppColors.secondaryText,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.secondaryText,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterStores('');
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.secondaryText,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14, // Adjusted for better vertical centering
          ),
        ),
        onChanged: _filterStores,
      ),
    );
  }

  Widget _buildLocationButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 180, // Position below legend
      right: 16,
      child: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _centerOnUserLocation,
              icon: Icon(
                Icons.my_location,
                color: locationProvider.hasLocationPermission
                    ? AppColors.themeRed
                    : AppColors.secondaryText,
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildStoreDetailsSheet() {
    if (_selectedStore == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {}, // Prevent tap-through to map
        child: Container(
          // ADDED: A max-height constraint to prevent the sheet from being too tall,
          // while still allowing it to fit its content.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6, // Max 60% of screen height
          ),
          // REMOVED: The fixed height property is gone. The height is now intrinsic.
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false, // Correct: disables top safe area padding
            child: Column(
              // IMPORTANT: This makes the sheet's height wrap its content.
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar (non-scrolling part)
                Padding(
                  padding: EdgeInsets.only(
                    top: ResponsiveUtils.getResponsiveSpacing(context, 8),
                    bottom: ResponsiveUtils.getResponsiveSpacing(context, 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // All content is now in a Flexible, scrollable container
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        ResponsiveUtils.getResponsiveSpacing(context, 20),
                        ResponsiveUtils.getResponsiveSpacing(context, 16),
                        ResponsiveUtils.getResponsiveSpacing(context, 20),
                        ResponsiveUtils.getResponsiveSpacing(context, 24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store info header
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.lightRed,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.store,
                                  color: AppColors.themeRed,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedStore!.name,
                                      style: AppTextStyles.responsiveMajorHeader(context).copyWith(
                                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightRed,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _selectedStore!.type.displayName,
                                        style: AppTextStyles.responsiveBodySmall(context).copyWith(
                                          color: AppColors.themeRed,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                        target: LatLng(
                                          _selectedStore!.latitude,
                                          _selectedStore!.longitude,
                                        ),
                                        zoom: 17.0,
                                      ),
                                    ),
                                  );
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightRed,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.center_focus_strong,
                                    color: AppColors.themeRed,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 20)),
                          // Address and distance info
                          Container(
                            padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 16)),
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: AppColors.themeRed,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedStore!.address,
                                        style: AppTextStyles.responsiveBody(context),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 12)),
                                Consumer<LocationProvider>(
                                  builder: (context, locationProvider, child) {
                                    final distance = locationProvider.getFormattedDistanceToStore(_selectedStore!);
                                    final walkingTime = locationProvider.getFormattedWalkingTimeToStore(_selectedStore!);
                                    if (distance != null && walkingTime != null) {
                                      return Row(
                                        children: [
                                          Icon(
                                            Icons.directions_walk,
                                            color: AppColors.themeRed,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$distance • $walkingTime',
                                            style: AppTextStyles.responsiveBody(context).copyWith(
                                              color: AppColors.themeRed,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedStore = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                  label: const Text('关闭'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveUtils.getResponsiveSpacing(context, 14),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 16)),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _navigateToStore(_selectedStore!);
                                  },
                                  icon: const Icon(Icons.navigation),
                                  label: const Text('导航'),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: ResponsiveUtils.getResponsiveSpacing(context, 14),
                                    ),
                                    backgroundColor: AppColors.themeRed,
                                    foregroundColor: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigate to selected store using external maps app
  void _navigateToStore(Store store) async {
    try {
      // Create platform-specific URLs for better integration
      Uri url;

      if (Platform.isIOS) {
        // Use Apple Maps on iOS
        url = Uri.parse('http://maps.apple.com/?q=${store.latitude},${store.longitude}');
      } else {
        // Use Google Maps on Android and other platforms
        url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}');
      }

      // Try to launch the URL
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Open in external app
        );

        // Close store details after successful launch
        setState(() {
          _selectedStore = null;
        });
      } else {
        // Fallback: show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('无法打开地图应用'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors
      debugPrint('Error launching maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导航失败: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _centerOnUserLocation() async {
    final locationProvider = context.read<LocationProvider>();

    debugPrint('_centerOnUserLocation called - hasPermission: ${locationProvider.hasLocationPermission}, controller: $_mapController');

    // First try to get fresh location if we don't have permission
    if (!locationProvider.hasLocationPermission) {
      debugPrint('No location permission, requesting...');
      final granted = await locationProvider.requestLocationPermission();
      if (!granted) {
        debugPrint('Location permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('请在设置中允许位置权限，然后重新打开应用'),
              backgroundColor: AppColors.themeRed,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: '设置',
                textColor: Colors.white,
                onPressed: () {
                  // This will open the app settings
                  openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }
    }

    // Try to refresh location if we don't have a current position
    if (locationProvider.currentPosition == null) {
      debugPrint('No current position, refreshing location...');
      await locationProvider.updateLocation();
    }

    final userPosition = locationProvider.currentPosition;

    if (userPosition != null && _mapController != null) {
      debugPrint('Centering map on user location: ${userPosition.latitude}, ${userPosition.longitude}');

      try {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(userPosition.latitude, userPosition.longitude),
              zoom: 17.0,
            ),
          ),
        );
        debugPrint('Successfully centered map on user location');
      } catch (e) {
        debugPrint('Error animating camera: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('地图定位失败'),
              backgroundColor: AppColors.themeRed,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      debugPrint('Cannot center on user location: position=$userPosition, controller=$_mapController');

      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('无法获取当前位置'),
            backgroundColor: AppColors.themeRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

}
