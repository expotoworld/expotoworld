import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';
import '../providers/mini_app_providers.dart';

/// Map screen for mini-apps showing only stores of the relevant type
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
  // ignore: unused_field
  MiniAppStore? _selectedStore;

  // Default location - Lugano, Switzerland
  static const LatLng _defaultLocation = LatLng(46.0037, 8.9511);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildMarkers();
    });
  }

  void _buildMarkers() {
    final stores = ref.read(miniAppStoresProvider(widget.miniAppType));
    
    setState(() {
      _markers = stores.map((store) {
        return Marker(
          markerId: MarkerId(store.id),
          position: store.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getHueForStoreType(store.storeType),
          ),
          onTap: () => _showStoreDetails(store),
        );
      }).toSet();
    });
  }

  double _getHueForStoreType(StoreType storeType) {
    switch (storeType) {
      case StoreType.mega:
        return BitmapDescriptor.hueBlue;
      case StoreType.market:
        return BitmapDescriptor.hueGreen;
      case StoreType.toGo:
        return BitmapDescriptor.hueViolet;
      case StoreType.xpress:
        return BitmapDescriptor.hueYellow;
    }
  }

  void _showStoreDetails(MiniAppStore store) {
    setState(() => _selectedStore = store);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _StoreDetailsSheet(
        store: store,
        onSelectStore: () {
          // Set as selected store and navigate to home
          ref.read(selectedStoreProvider(widget.miniAppType).notifier).state = store;
          Navigator.pop(context);
          context.go('/mini-app/${widget.miniAppType.name}/home');
        },
        onGetDirections: () {
          // TODO: Open maps for directions
          Navigator.pop(context);
        },
      ),
    );
  }

  void _handleClose() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final stores = ref.watch(miniAppStoresProvider(widget.miniAppType));
    final selectedStore = ref.watch(selectedStoreProvider(widget.miniAppType));

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: const BoxDecoration(
              color: AppColors.themeRed,
            ),
            child: _MapHeader(
              title: 'Nearby Stores',
              storeCount: stores.length,
              onClose: _handleClose,
            ),
          ),
          
          // Map
          Expanded(
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedStore?.location ?? _defaultLocation,
                    zoom: 13,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController.complete(controller);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                
                // Store list button
                Positioned(
                  bottom: 100,
                  right: AppSpacing.lg,
                  child: _StoreListFab(
                    onTap: () => _showStoreList(stores),
                  ),
                ),
                
                // Current location button
                Positioned(
                  bottom: 160,
                  right: AppSpacing.lg,
                  child: _LocationFab(
                    onTap: _goToCurrentLocation,
                  ),
                ),
              ],
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
      builder: (context) => _StoreListSheet(
        stores: stores,
        onStoreTap: (store) {
          Navigator.pop(context);
          _animateToStore(store);
          _showStoreDetails(store);
        },
      ),
    );
  }

  Future<void> _animateToStore(MiniAppStore store) async {
    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(store.location, 15),
    );
  }

  Future<void> _goToCurrentLocation() async {
    // For now, just center on default location
    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_defaultLocation, 14),
    );
  }
}

/// Map header
class _MapHeader extends StatelessWidget {
  final String title;
  final int storeCount;
  final VoidCallback onClose;

  const _MapHeader({
    required this.title,
    required this.storeCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$storeCount stores available',
                  style: AppTypography.caption(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // Close button
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Store list floating action button
class _StoreListFab extends StatelessWidget {
  final VoidCallback onTap;

  const _StoreListFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.themeRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.list_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

/// Current location floating action button
class _LocationFab extends StatelessWidget {
  final VoidCallback onTap;

  const _LocationFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.my_location_rounded,
          color: AppColors.themeRed,
          size: 24,
        ),
      ),
    );
  }
}

/// Store details bottom sheet
class _StoreDetailsSheet extends StatelessWidget {
  final MiniAppStore store;
  final VoidCallback onSelectStore;
  final VoidCallback onGetDirections;

  const _StoreDetailsSheet({
    required this.store,
    required this.onSelectStore,
    required this.onGetDirections,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
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
          
          // Store info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                // Store type icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: store.storeType.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    store.storeType.icon,
                    color: store.storeType.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                
                // Store details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: store.storeType.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          store.storeType.displayName,
                          style: AppTypography.caption(
                            color: store.storeType.color,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.name,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.foreground(context),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        size: 14,
                        color: AppColors.foregroundMuted(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.formattedDistance,
                        style: AppTypography.labelSmallStyle.copyWith(
                          color: AppColors.foreground(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Action buttons
          Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: bottomPadding + AppSpacing.md,
            ),
            child: Row(
              children: [
                // Directions button
                Expanded(
                  child: GestureDetector(
                    onTap: onGetDirections,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_rounded,
                            color: AppColors.foreground(context),
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Directions',
                            style: AppTypography.labelMediumStyle.copyWith(
                              color: AppColors.foreground(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                
                // Select store button
                Expanded(
                  child: GestureDetector(
                    onTap: onSelectStore,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.themeRed,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.themeRed.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_bag_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Shop Here',
                            style: AppTypography.labelMediumStyle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
          top: Radius.circular(AppSpacing.radiusXl),
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
