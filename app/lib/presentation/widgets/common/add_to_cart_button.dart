import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/mini_app_navigation.dart';
import '../../../core/enums/mini_app_type.dart';
import '../../../data/models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

class AddToCartButton extends StatelessWidget {
  final Product product;
  final bool isInHotRecommendations;

  const AddToCartButton({
    super.key,
    required this.product,
    this.isInHotRecommendations = false,
  });

  @override
  Widget build(BuildContext context) {
    // Hide add-to-cart button in hot recommendations section
    if (isInHotRecommendations) {
      return const SizedBox.shrink();
    }

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final quantity = cartProvider.getProductQuantity(product.id);

        if (quantity == 0) {
          // Show circular "+" button with MOQ indicator if needed
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _handleAddToCart(context, cartProvider, 0),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.themeRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
              // Show MOQ indicator if MOQ > 1
              if (product.minimumOrderQuantity > 1) ...[
                const SizedBox(height: 4),
                Text(
                  '最小起订量: ${product.minimumOrderQuantity}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.themeRed,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        } else {
          // Show pill-shaped quantity controls
          return Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.themeRed,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minus button
                GestureDetector(
                  onTap: () => _handleRemoveFromCart(context, cartProvider, quantity),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
                
                // Quantity display
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  child: Text(
                    quantity.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                // Plus button
                GestureDetector(
                  onTap: () => _handleAddToCart(context, cartProvider, quantity),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _canAddMore(quantity) ? null : AppColors.secondaryText,
                    ),
                    child: Icon(
                      Icons.add,
                      color: _canAddMore(quantity) ? AppColors.white : Colors.white70,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  /// Check if more items can be added based on stock availability
  bool _canAddMore(int currentQuantity) {
    // Only 无人商店 (UnmannedStore) mini-app validates stock
    // All other mini-apps have infinite stock
    if (product.miniAppType != MiniAppType.unmannedStore) {
      return true;
    }

    // For unmanned stores, validate stock
    // If displayStock is null, treat as unlimited stock (N/A stock status)
    if (product.displayStock == null) return true;

    // If displayStock is 0 or negative, no stock available
    if (product.displayStock! <= 0) return false;

    // For initial add (currentQuantity = 0), check if we can add MOQ
    if (currentQuantity == 0 && product.minimumOrderQuantity > 1) {
      return product.displayStock! >= product.minimumOrderQuantity;
    }

    // For subsequent adds, always increment by 1
    return product.displayStock! >= (currentQuantity + 1);
  }

  /// Handle add to cart with stock validation and MOQ logic
  void _handleAddToCart(BuildContext context, CartProvider cartProvider, int currentQuantity) async {
    debugPrint('🛒 AddToCartButton: _handleAddToCart called for product ${product.id}');
    debugPrint('🛒 AddToCartButton: Current quantity: $currentQuantity');
    debugPrint('🛒 AddToCartButton: Product MOQ: ${product.minimumOrderQuantity}');
    debugPrint('🛒 AddToCartButton: Product displayStock: ${product.displayStock}');
    debugPrint('🛒 AddToCartButton: Product storeType: ${product.storeType}');
    debugPrint('🛒 AddToCartButton: Product miniAppType: ${product.miniAppType}');

    // Ensure mini-app context is set based on product's mini-app type
    _ensureMiniAppContext(cartProvider);

    // Validate authentication and context before proceeding
    if (!_validateCartContext(context, cartProvider)) {
      return;
    }

    // Check stock limits first
    if (!_canAddMore(currentQuantity)) {
      debugPrint('🛒 AddToCartButton: Stock limit reached, showing feedback');
      _showStockLimitFeedback(context);
      return;
    }

    debugPrint('🛒 AddToCartButton: Stock check passed, proceeding with add to cart');

    try {
      // For initial add to cart, add with MOQ quantity if MOQ > 1
      if (currentQuantity == 0 && product.minimumOrderQuantity > 1) {
        // Check if we can add MOQ quantity (only if stock is tracked)
        if (product.displayStock != null &&
            product.displayStock! > 0 &&
            product.minimumOrderQuantity > product.displayStock!) {
          debugPrint('🛒 AddToCartButton: MOQ exceeds stock, showing feedback');
          _showStockLimitFeedback(context);
          return;
        }
        debugPrint('🛒 AddToCartButton: Adding product with MOQ quantity: ${product.minimumOrderQuantity}');
        await cartProvider.addProductWithQuantity(product, product.minimumOrderQuantity);
      } else {
        // For subsequent adds, always increment by 1 (regular increment)
        debugPrint('🛒 AddToCartButton: Adding product with regular increment');
        await cartProvider.addProduct(product);
      }

      debugPrint('🛒 AddToCartButton: Cart operation completed successfully');

      // Check if widget is still mounted before using context
      if (context.mounted) {
        _showAddToCartFeedback(context);

        // If in hot recommendations, redirect to mini-app cart
        if (isInHotRecommendations) {
          _handleHotRecommendationRedirect(context);
        }
      }
    } catch (e) {
      debugPrint('🛒 AddToCartButton: Error during cart operation: $e');

      // Check if widget is still mounted before using context
      if (context.mounted) {
        // Show error feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加到购物车失败: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// Handle remove from cart with MOQ logic
  void _handleRemoveFromCart(BuildContext context, CartProvider cartProvider, int currentQuantity) {
    if (currentQuantity <= 0) return;

    // If current quantity is at MOQ or below, remove product entirely
    if (currentQuantity <= product.minimumOrderQuantity) {
      cartProvider.removeAllOfProduct(product.id);
    } else {
      // Regular decrement
      cartProvider.removeProduct(product.id);
    }
  }

  /// Ensure mini-app context is set for cart operations
  void _ensureMiniAppContext(CartProvider cartProvider) {
    // Set mini-app context based on product's mini-app type
    final miniAppTypeString = product.miniAppType.apiValue;
    debugPrint('🛒 AddToCartButton: Setting mini-app context to: $miniAppTypeString');

    // For location-based mini-apps, we might need store ID
    int? storeId;
    if (product.storeId != null &&
        (product.miniAppType == MiniAppType.unmannedStore ||
         product.miniAppType == MiniAppType.exhibitionSales)) {
      storeId = int.tryParse(product.storeId!);
      debugPrint('🛒 AddToCartButton: Setting store ID: $storeId');
    }

    cartProvider.setMiniAppContext(miniAppTypeString, storeId: storeId);
  }

  /// Show feedback when stock limit is reached
  void _showStockLimitFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          product.displayStock != null && product.displayStock! > 0
              ? '库存不足！仅剩 ${product.displayStock} 件'
              : '商品已售罄',
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showAddToCartFeedback(BuildContext context) {
    // Simple scale animation feedback
    // In a real app, you might want to show a snackbar or more elaborate animation
  }

  void _handleHotRecommendationRedirect(BuildContext context) {
    // Add a small delay to allow the cart update to complete and show feedback
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        MiniAppNavigation.navigateToMiniAppCart(context, product);
      }
    });
  }

  /// Validate cart context and authentication before cart operations
  bool _validateCartContext(BuildContext context, CartProvider cartProvider) {
    // Get auth provider to check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check authentication first
    if (!authProvider.isAuthenticated) {
      debugPrint('🛒 AddToCartButton: User not authenticated');
      _showErrorFeedback(context, '请先登录后再添加商品到购物车');
      return false;
    }

    // Check if mini-app context is set
    if (cartProvider.currentMiniAppType == null) {
      debugPrint('🛒 AddToCartButton: Mini-app context not set');
      _showErrorFeedback(context, '购物车初始化失败，请重试');
      return false;
    }

    // For location-based mini-apps, check if store is selected
    if ((product.miniAppType == MiniAppType.unmannedStore ||
         product.miniAppType == MiniAppType.exhibitionSales) &&
        (product.storeId == null || product.storeId!.isEmpty)) {
      debugPrint('🛒 AddToCartButton: Location-based mini-app requires store selection');
      _showErrorFeedback(context, '请先选择门店位置');
      return false;
    }

    return true;
  }

  /// Show error feedback to user
  void _showErrorFeedback(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
