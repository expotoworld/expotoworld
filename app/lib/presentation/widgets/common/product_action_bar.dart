import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/enums/mini_app_type.dart';
import '../../../data/models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

class ProductActionBar extends StatelessWidget {
  final Product product;

  const ProductActionBar({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtils.getResponsiveSpacing(context, 16),
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left side - MOQ display
            if (product.minimumOrderQuantity > 1) _buildMOQDisplay(context),
            
            // Spacer to push button to the right
            const Spacer(),
            
            // Right side - Add to cart button/stepper
            _buildAddToCartSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMOQDisplay(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.responsiveBody(context),
        children: [
          const TextSpan(
            text: '最小起订量: ',
          ),
          TextSpan(
            text: product.minimumOrderQuantity.toString(),
            style: AppTextStyles.responsiveBody(context).copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.themeRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToCartSection(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final quantity = cartProvider.getProductQuantity(product.id);
        
        if (quantity == 0) {
          // Show "加入购物车" button
          return _buildAddToCartButton(context, cartProvider);
        } else {
          // Show quantity stepper
          return _buildQuantityStepper(context, cartProvider, quantity);
        }
      },
    );
  }

  Widget _buildAddToCartButton(BuildContext context, CartProvider cartProvider) {
    return GestureDetector(
      onTap: () async {
        // Validate authentication and context before proceeding
        if (!_validateCartContext(context, cartProvider)) {
          return;
        }

        try {
          // Add product with MOQ quantity
          final initialQuantity = product.minimumOrderQuantity;
          if (initialQuantity > 1) {
            // For MOQ > 1, add with specific quantity
            await cartProvider.addProductWithQuantity(product, initialQuantity);
          } else {
            // For MOQ = 1, use regular add
            await cartProvider.addProduct(product);
          }

          // Check if context is still mounted before using it
          if (context.mounted) {
            _showAddToCartFeedback(context);
          }
        } catch (e) {
          debugPrint('🛒 ProductActionBar: Error adding to cart: $e');
          // Check if context is still mounted before using it
          if (context.mounted) {
            _showErrorFeedback(context, '添加到购物车失败，请重试');
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context, 24),
          vertical: ResponsiveUtils.getResponsiveSpacing(context, 12),
        ),
        decoration: BoxDecoration(
          color: AppColors.themeRed,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '加入购物车',
          style: AppTextStyles.responsiveButton(context),
        ),
      ),
    );
  }

  Widget _buildQuantityStepper(BuildContext context, CartProvider cartProvider, int quantity) {
    // Always allow decrease - MOQ logic will be handled in the tap handler
    final canDecrease = quantity > 0;

    return Container(
      height: ResponsiveUtils.getResponsiveSpacing(context, 44),
      decoration: BoxDecoration(
        color: AppColors.themeRed,
        borderRadius: BorderRadius.circular(22),
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
            onTap: canDecrease
                ? () => _handleRemoveFromCart(context, cartProvider, quantity)
                : null,
            child: Container(
              width: ResponsiveUtils.getResponsiveSpacing(context, 44),
              height: ResponsiveUtils.getResponsiveSpacing(context, 44),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove,
                color: canDecrease ? AppColors.white : AppColors.white.withValues(alpha: 0.5),
                size: ResponsiveUtils.getResponsiveSpacing(context, 18),
              ),
            ),
          ),
          
          // Quantity display
          Container(
            constraints: BoxConstraints(
              minWidth: ResponsiveUtils.getResponsiveSpacing(context, 32),
            ),
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: AppTextStyles.responsiveButton(context),
            ),
          ),
          
          // Plus button
          GestureDetector(
            onTap: () {
              cartProvider.addProduct(product);
              _showAddToCartFeedback(context);
            },
            child: Container(
              width: ResponsiveUtils.getResponsiveSpacing(context, 44),
              height: ResponsiveUtils.getResponsiveSpacing(context, 44),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: AppColors.white,
                size: ResponsiveUtils.getResponsiveSpacing(context, 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCartFeedback(BuildContext context) {
    // Simple haptic feedback or animation could be added here
    // For now, we'll keep it simple like the existing AddToCartButton
  }

  /// Handle remove from cart with MOQ logic
  void _handleRemoveFromCart(BuildContext context, CartProvider cartProvider, int currentQuantity) {
    debugPrint('🛒 ProductActionBar: _handleRemoveFromCart called for product ${product.id}');
    debugPrint('🛒 ProductActionBar: Current quantity: $currentQuantity');
    debugPrint('🛒 ProductActionBar: Product MOQ: ${product.minimumOrderQuantity}');

    if (currentQuantity <= 0) return;

    // If current quantity is at MOQ or below, remove product entirely
    if (currentQuantity <= product.minimumOrderQuantity) {
      debugPrint('🛒 ProductActionBar: Quantity at or below MOQ, removing product entirely');
      cartProvider.removeAllOfProduct(product.id);
    } else {
      // Regular decrement
      debugPrint('🛒 ProductActionBar: Regular decrement');
      cartProvider.removeProduct(product.id);
    }
  }

  /// Validate cart context and authentication before cart operations
  bool _validateCartContext(BuildContext context, CartProvider cartProvider) {
    // Get auth provider to check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check authentication first
    if (!authProvider.isAuthenticated) {
      debugPrint('🛒 ProductActionBar: User not authenticated');
      _showErrorFeedback(context, '请先登录后再添加商品到购物车');
      return false;
    }

    // Check if mini-app context is set
    if (cartProvider.currentMiniAppType == null) {
      debugPrint('🛒 ProductActionBar: Mini-app context not set');
      _showErrorFeedback(context, '购物车初始化失败，请重试');
      return false;
    }

    // For location-based mini-apps, check if store is selected
    if ((product.miniAppType == MiniAppType.unmannedStore ||
         product.miniAppType == MiniAppType.exhibitionSales) &&
        (product.storeId == null || product.storeId!.isEmpty)) {
      debugPrint('🛒 ProductActionBar: Location-based mini-app requires store selection');
      _showErrorFeedback(context, '请先选择门店位置');
      return false;
    }

    return true;
  }

  /// Show error feedback to user
  void _showErrorFeedback(BuildContext context, String message) {
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
