import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../../data/models/store.dart';
import '../../../../data/services/api_service.dart';
import '../../../../core/enums/store_type.dart';
import '../../../providers/location_provider.dart';

class ExhibitionSalesLocationsScreen extends StatefulWidget {
  const ExhibitionSalesLocationsScreen({super.key});

  @override
  State<ExhibitionSalesLocationsScreen> createState() => _ExhibitionSalesLocationsScreenState();
}

class _ExhibitionSalesLocationsScreenState extends State<ExhibitionSalesLocationsScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Store? _selectedStore;
  final ApiService _apiService = ApiService();
  List<Store> _allStores = [];
  List<Store> _filteredStores = [];

  // Legend filtering state - only exhibition store types
  final Map<StoreType, bool> _storeTypeVisibility = {
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
    // Pre-load standard markers for exhibition store types
    for (final storeType in [StoreType.exhibitionStore, StoreType.exhibitionMall]) {
      _markerCache[storeType] = await MapMarkerUtils.getStoreMarkerIcon(storeType);
    }
    if (mounted) setState(() {});
  }

  Future<List<Store>> _loadExhibitionStores() async {
    try {
      final stores = await _apiService.fetchStores();
      // Filter for exhibition stores only (展销商店 and 展销商城)
      return stores.where((store) =>
        store.type == StoreType.exhibitionStore ||
        store.type == StoreType.exhibitionMall
      ).toList();
    } catch (e) {
      debugPrint('Error loading exhibition stores: $e');
      return [];
    }
  }

  void _loadStores() async {
    try {
      final stores = await _loadExhibitionStores();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
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
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildSearchBar()), // Uses the new method
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
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
            child: Text('暂无展销展消数据'),
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
                  markerId: MarkerId(store.id),
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



  Widget _buildSearchBar() {
    return Container(
      height: 48,
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
          hintText: '搜索展销展消...', // Customized hint text
          hintStyle: AppTextStyles.body.copyWith(
            color: AppColors.secondaryText,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterStores('');
                  },
                  icon: const Icon(Icons.clear, color: AppColors.secondaryText),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            style: AppTextStyles.responsiveBodySmall(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
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
              style: AppTextStyles.responsiveBodySmall(context).copyWith(
                color: isVisible ? AppColors.secondaryText : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreDetailsSheet() {
    if (_selectedStore == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300]!,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Store info
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.lightRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppColors.themeRed,
                    size: 30,
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
                          fontSize: 20,
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
              ],
            ),

            const SizedBox(height: 16),

            // Address
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.secondaryText,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedStore!.address,
                    style: AppTextStyles.responsiveBody(context).copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to store or show directions
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.themeRed,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '导航',
                  style: AppTextStyles.responsiveBody(context).copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to fit map bounds to show all stores
  void _fitMapToStores(GoogleMapController controller, List<Store> stores, Position? userPosition) {
    if (stores.isEmpty) return;

    double minLat = stores.first.latitude;
    double maxLat = stores.first.latitude;
    double minLng = stores.first.longitude;
    double maxLng = stores.first.longitude;

    for (final store in stores) {
      minLat = minLat < store.latitude ? minLat : store.latitude;
      maxLat = maxLat > store.latitude ? maxLat : store.latitude;
      minLng = minLng < store.longitude ? minLng : store.longitude;
      maxLng = maxLng > store.longitude ? maxLng : store.longitude;
    }

    // Include user position if available
    if (userPosition != null) {
      minLat = minLat < userPosition.latitude ? minLat : userPosition.latitude;
      maxLat = maxLat > userPosition.latitude ? maxLat : userPosition.latitude;
      minLng = minLng < userPosition.longitude ? minLng : userPosition.longitude;
      maxLng = maxLng > userPosition.longitude ? maxLng : userPosition.longitude;
    }

    // Add padding
    const padding = 0.01;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  void _centerOnUserLocation() async {
    final locationProvider = context.read<LocationProvider>();

    if (!locationProvider.hasLocationPermission) {
      // Request permission first
      await locationProvider.requestLocationPermission();
      if (!locationProvider.hasLocationPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要位置权限才能显示您的位置'),
              backgroundColor: AppColors.themeRed,
            ),
          );
        }
        return;
      }
    }

    try {
      // Get current position
      final position = locationProvider.currentPosition;
      if (position != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16.0,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法获取当前位置'),
              backgroundColor: AppColors.themeRed,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('获取位置失败'),
            backgroundColor: AppColors.themeRed,
          ),
        );
      }
    }
  }
}
