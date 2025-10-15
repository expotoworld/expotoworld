import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/cart_provider.dart';

import 'cart_screen.dart';

/// Wrapper for cart screen that maintains bottom navigation context for location-based mini-apps
class CartScreenWrapper extends StatefulWidget {
  final String miniAppType; // 'unmanned_store' or 'exhibition_sales'
  final String? instanceId;
  final int? storeId; // Store ID for location-based mini-apps

  const CartScreenWrapper({
    super.key,
    required this.miniAppType,
    this.instanceId,
    this.storeId,
  });

  @override
  State<CartScreenWrapper> createState() => _CartScreenWrapperState();
}

class _CartScreenWrapperState extends State<CartScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize cart context for the specific mini-app, preserving existing store_id
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Normalize mini-app type to PascalCase format expected by CartScreen
      final normalizedMiniAppType = _normalizeMiniAppType(widget.miniAppType);
      debugPrint('🛒 CartScreenWrapper: Normalized mini-app type from ${widget.miniAppType} to $normalizedMiniAppType');

      // Check if cart context is already set for this mini-app and preserve store_id
      if (cartProvider.currentMiniAppType == normalizedMiniAppType && cartProvider.currentStoreId != null) {
        debugPrint('🛒 CartScreenWrapper: Cart context already set for $normalizedMiniAppType, preserving store ID: ${cartProvider.currentStoreId}');
      } else {
        // Set context with store_id if provided, otherwise use existing store_id
        final storeId = widget.storeId ?? cartProvider.currentStoreId;
        cartProvider.setMiniAppContext(normalizedMiniAppType, storeId: storeId);
        debugPrint('🛒 CartScreenWrapper: Cart context initialized for $normalizedMiniAppType with store ID: $storeId');
      }
    });
  }

  /// Normalize mini-app type to PascalCase format expected by CartScreen
  String _normalizeMiniAppType(String miniAppType) {
    switch (miniAppType.toLowerCase()) {
      case 'unmanned_store':
      case 'unmannedstore':
        return 'UnmannedStore';
      case 'exhibition_sales':
      case 'exhibitionsales':
        return 'ExhibitionSales';
      case 'retail_store':
      case 'retailstore':
        return 'RetailStore';
      case 'group_buying':
      case 'groupbuying':
        return 'GroupBuying';
      default:
        // If already in correct format, return as-is
        return miniAppType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const CartScreen(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              // Left nav items
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.home,
                      label: '首页',
                      onTap: () => _navigateToHome(),
                    ),
                    _buildNavItem(
                      icon: Icons.location_on,
                      label: '地点',
                      onTap: () => _navigateToLocation(),
                    ),
                  ],
                ),
              ),

              // Center FAB for cart (current screen, so highlighted)
              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  return Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.themeRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.shopping_cart,
                            color: AppColors.white,
                            size: 24,
                          ),
                        ),
                        if (cartProvider.itemCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                cartProvider.itemCount.toString(),
                                style: const TextStyle(
                                  color: AppColors.themeRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // Right nav items
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.message,
                      label: '消息',
                      onTap: () => _navigateToMessages(),
                    ),
                    _buildNavItem(
                      icon: Icons.person,
                      label: '我的',
                      onTap: () => _navigateToProfile(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.themeRed : AppColors.secondaryText,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: isSelected
                  ? AppTextStyles.navActive
                  : AppTextStyles.navInactive,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHome() {
    // Navigate back to the mini-app home screen
    Navigator.of(context).pop();
  }

  void _navigateToLocation() {
    // Navigate back to the mini-app and switch to location tab
    Navigator.of(context).pop();
    // Note: The parent mini-app should handle switching to location tab
  }

  void _navigateToMessages() {
    // Navigate back to the mini-app and switch to messages tab
    Navigator.of(context).pop();
    // Note: The parent mini-app should handle switching to messages tab
  }

  void _navigateToProfile() {
    // Navigate back to the mini-app and switch to profile tab
    Navigator.of(context).pop();
    // Note: The parent mini-app should handle switching to profile tab
  }
}
