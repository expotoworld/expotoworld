import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/store.dart';
import '../../../data/services/location_service.dart';

class MapFallback extends StatelessWidget {
  final List<Store> stores;
  final Function(Store)? onStoreSelected;

  const MapFallback({
    super.key,
    required this.stores,
    this.onStoreSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Map placeholder header
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.lightRed,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: AppColors.themeRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    kIsWeb ? '地图视图 (Web版本)' : '地图视图',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.themeRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kIsWeb 
                        ? '请在移动设备上查看完整地图功能'
                        : '显示附近的无人门店位置',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Store markers simulation
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '附近的无人商店 (${stores.length})',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: stores.length,
                      itemBuilder: (context, index) {
                        final store = stores[index];
                        return _buildStoreMarker(context, store, index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreMarker(BuildContext context, Store store, int index) {
    return GestureDetector(
      onTap: () => onStoreSelected?.call(store),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Marker icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.themeRed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Store info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.address,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Distance info (if available)
            FutureBuilder<double?>(
              future: _getDistanceToStore(store),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final distance = LocationService.formatDistance(snapshot.data!);
                  return Text(
                    distance,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.themeRed,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<double?> _getDistanceToStore(Store store) async {
    try {
      final userPosition = LocationService.cachedPosition;
      if (userPosition == null) return null;
      
      return LocationService.calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        store.latitude,
        store.longitude,
      );
    } catch (e) {
      return null;
    }
  }
}
