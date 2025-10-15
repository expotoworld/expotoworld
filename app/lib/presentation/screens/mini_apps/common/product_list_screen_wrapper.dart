import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/subcategory.dart';
import '../../../../data/models/product.dart';
import '../../../../data/models/store.dart';
import '../../../providers/cart_provider.dart';
import '../../cart/cart_screen_wrapper.dart';
import 'product_list_screen.dart';

/// Wrapper for product list screen that maintains mini-app navigation context
class ProductListScreenWrapper extends StatefulWidget {
  final Category category;
  final Subcategory subcategory;
  final List<Product> allProducts;
  final String miniAppName;
  final String miniAppType; // 'unmanned_store' or 'exhibition_sales'
  final Store? selectedStore;
  final String? instanceId;

  const ProductListScreenWrapper({
    super.key,
    required this.category,
    required this.subcategory,
    required this.allProducts,
    required this.miniAppName,
    required this.miniAppType,
    this.selectedStore,
    this.instanceId,
  });

  @override
  State<ProductListScreenWrapper> createState() => _ProductListScreenWrapperState();
}

class _ProductListScreenWrapperState extends State<ProductListScreenWrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ProductListScreen(
        category: widget.category,
        subcategory: widget.subcategory,
        allProducts: widget.allProducts,
        miniAppName: widget.miniAppName,
        selectedStore: widget.selectedStore,
      ),
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

              // Center FAB for cart
              Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  return GestureDetector(
                    onTap: () => _navigateToCart(),
                    child: Container(
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

  void _navigateToCart() {
    // Navigate to cart screen with wrapper
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CartScreenWrapper(
          miniAppType: widget.miniAppType,
          instanceId: widget.instanceId,
          storeId: widget.selectedStore?.id != null ? int.tryParse(widget.selectedStore!.id) : null,
        ),
        transitionDuration: Duration.zero, // Instant transition
        reverseTransitionDuration: Duration.zero, // Instant reverse transition
      ),
    );
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
