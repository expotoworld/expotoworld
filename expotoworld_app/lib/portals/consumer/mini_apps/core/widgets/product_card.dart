import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/models/product_model.dart';

/// Product card for mini-apps with add-to-cart counter
/// Supports masonry layout with varying heights
class MiniAppProductCard extends StatelessWidget {
  final MiniAppProduct product;
  final int cartQuantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onTap;
  final bool showMasonry; // Whether to use variable height for masonry layout

  const MiniAppProductCard({
    super.key,
    required this.product,
    required this.cartQuantity,
    required this.onQuantityChanged,
    this.onTap,
    this.showMasonry = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with badges
            _ProductImageSection(product: product),
            
            // Product info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: AppTypography.labelMediumStyle.copyWith(
                      color: AppColors.foreground(context),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  
                  // Weight
                  if (product.weight.isNotEmpty)
                    Text(
                      product.weight,
                      style: AppTypography.caption(
                        color: AppColors.foregroundMuted(context),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Prices
                  _PriceSection(product: product),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Add to cart section
                  _AddToCartSection(
                    product: product,
                    quantity: cartQuantity,
                    onQuantityChanged: onQuantityChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product image section with discount badge and stock indicator
class _ProductImageSection extends StatelessWidget {
  final MiniAppProduct product;

  const _ProductImageSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusMd - 1),
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(isDark),
                    )
                  : _buildPlaceholder(isDark),
            ),
          ),
          
          // Discount badge
          if (product.hasDiscount)
            Positioned(
              top: AppSpacing.xs,
              left: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.themeRed,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '-${product.discountPercent}%',
                  style: AppTypography.caption(color: Colors.white).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          
          // Low stock indicator
          if (product.stockLeft <= 5 && product.stockLeft > 0)
            Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Only ${product.stockLeft}',
                  style: AppTypography.caption(color: Colors.white).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          
          // Out of stock overlay
          if (!product.isInStock)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd - 1),
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Out of Stock',
                    style: AppTypography.labelSmallStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.shopping_basket_rounded,
        size: 40,
        color: isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.grey.shade300,
      ),
    );
  }
}

/// Price section with original and current prices
class _PriceSection extends StatelessWidget {
  final MiniAppProduct product;

  const _PriceSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current price
        Text(
          product.formattedCurrentPrice,
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.themeRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Original price (if discounted)
        if (product.hasDiscount)
          Text(
            product.formattedOriginalPrice,
            style: AppTypography.caption(
              color: AppColors.foregroundMuted(context),
            ).copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
        
        // MOQ indicator
        if (product.showMoq)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Min. ${product.minimumOrderQuantity} units',
              style: AppTypography.caption(
                color: Colors.orange.shade700,
              ).copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }
}

/// Add to cart section with quantity counter
class _AddToCartSection extends StatelessWidget {
  final MiniAppProduct product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  const _AddToCartSection({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInCart = quantity > 0;

    // If not in cart, show "Add" button
    if (!isInCart) {
      return _AddButton(
        product: product,
        onAdd: () {
          HapticFeedback.lightImpact();
          // Start with MOQ if applicable
          final startQty = product.minimumOrderQuantity > 1 
              ? product.minimumOrderQuantity 
              : 1;
          onQuantityChanged(startQty);
        },
      );
    }

    // If in cart, show quantity counter
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.themeRed.withValues(alpha: 0.15)
            : AppColors.themeRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.themeRed.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Decrease button
          _CounterButton(
            icon: quantity <= product.minimumOrderQuantity
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              final newQty = quantity - 1;
              // If below MOQ, remove from cart (set to 0)
              if (newQty < product.minimumOrderQuantity) {
                onQuantityChanged(0);
              } else {
                onQuantityChanged(newQty);
              }
            },
            isDecrease: true,
          ),
          
          // Quantity display
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                style: AppTypography.labelMediumStyle.copyWith(
                  color: AppColors.themeRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Increase button
          _CounterButton(
            icon: Icons.add_rounded,
            onTap: quantity < product.stockLeft
                ? () {
                    HapticFeedback.lightImpact();
                    onQuantityChanged(quantity + 1);
                  }
                : null,
            isDecrease: false,
          ),
        ],
      ),
    );
  }
}

/// Add button (before item is in cart)
class _AddButton extends StatelessWidget {
  final MiniAppProduct product;
  final VoidCallback onAdd;

  const _AddButton({
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = !product.isInStock;

    return GestureDetector(
      onTap: isDisabled ? null : onAdd,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
              : AppColors.themeRed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.themeRed.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 18,
                color: isDisabled ? Colors.grey : Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                'Add',
                style: AppTypography.labelSmallStyle.copyWith(
                  color: isDisabled ? Colors.grey : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Counter button (+/-)
class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDecrease;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.isDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.transparent
              : AppColors.themeRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.horizontal(
            left: isDecrease
                ? const Radius.circular(AppSpacing.radiusMd)
                : Radius.zero,
            right: isDecrease
                ? Radius.zero
                : const Radius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: isDisabled
                ? AppColors.themeRed.withValues(alpha: 0.4)
                : AppColors.themeRed,
          ),
        ),
      ),
    );
  }
}

/// Service card for toX mini-app (Request Quote instead of Add to Cart)
class MiniAppServiceCard extends StatelessWidget {
  final MiniAppService service;
  final VoidCallback onRequestQuote;
  final VoidCallback? onTap;

  const MiniAppServiceCard({
    super.key,
    required this.service,
    required this.onRequestQuote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service image/icon area
            AspectRatio(
              aspectRatio: 1.3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.themeRed.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusMd - 1),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getIconForService(service.name),
                    size: 48,
                    color: AppColors.themeRed.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            
            // Service info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Provider badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.themeRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      service.provider,
                      style: AppTypography.caption(
                        color: AppColors.themeRed,
                      ).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Service name
                  Text(
                    service.name,
                    style: AppTypography.labelMediumStyle.copyWith(
                      color: AppColors.foreground(context),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  
                  // Service description
                  Text(
                    service.description,
                    style: AppTypography.caption(
                      color: AppColors.foregroundMuted(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Price info
                  if (service.priceRange != null)
                    Text(
                      service.priceRange!,
                      style: AppTypography.labelSmallStyle.copyWith(
                        color: AppColors.foreground(context),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (service.currentPrice != null)
                    Text(
                      service.displayPrice,
                      style: AppTypography.labelSmallStyle.copyWith(
                        color: AppColors.foreground(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Request Quote button
                  _RequestQuoteButton(onTap: onRequestQuote),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForService(String name) {
    final nameLower = name.toLowerCase();
    
    if (nameLower.contains('insurance') || nameLower.contains('assicurazione')) {
      if (nameLower.contains('car') || nameLower.contains('auto')) {
        return Icons.directions_car_rounded;
      }
      if (nameLower.contains('home') || nameLower.contains('casa')) {
        return Icons.home_rounded;
      }
      if (nameLower.contains('travel') || nameLower.contains('viaggio')) {
        return Icons.flight_rounded;
      }
      if (nameLower.contains('health') || nameLower.contains('salute')) {
        return Icons.health_and_safety_rounded;
      }
      return Icons.security_rounded;
    }
    if (nameLower.contains('mobile') || nameLower.contains('sim') || nameLower.contains('5g')) {
      return Icons.phone_android_rounded;
    }
    if (nameLower.contains('internet') || nameLower.contains('fiber') || nameLower.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (nameLower.contains('electric') || nameLower.contains('energy') || nameLower.contains('luce')) {
      return Icons.bolt_rounded;
    }
    if (nameLower.contains('gas')) {
      return Icons.local_fire_department_rounded;
    }
    
    return Icons.miscellaneous_services_rounded;
  }
}

/// Request Quote button for services
class _RequestQuoteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RequestQuoteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.themeRed, Color(0xFFFF5252)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.themeRed.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.request_quote_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Request Quote',
                style: AppTypography.labelSmallStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
