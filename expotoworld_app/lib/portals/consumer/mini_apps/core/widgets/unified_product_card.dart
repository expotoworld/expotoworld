import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../shared/widgets/marquee_text.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/product_model.dart';

/// Unified product card for all mini-apps and the super-app home screen
///
/// Features:
/// - Square product image
/// - Store type tag (MEGA, MARKET, to GO, XPRESS) with corresponding color
/// - Marquee text slider showing store name
/// - Large product name and price (most prominent elements)
/// - Strikethrough price next to actual price
/// - Extra info bubble (unit/quantity/multiplier)
/// - Oval add-to-cart button with cart icon
class UnifiedProductCard extends StatelessWidget {
  final MiniAppProduct product;
  final int cartQuantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onTap;

  const UnifiedProductCard({
    super.key,
    required this.product,
    required this.cartQuantity,
    required this.onQuantityChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Square product image with store type badge
            _ProductImageSection(product: product),

            // Marquee store name slider
            if (product.storeName != null)
              _StoreMarqueeSection(
                storeName: product.storeName!,
                storeType: product.storeType,
              ),

            // Product info section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product name (large and prominent, no truncation for masonry effect)
                  Text(
                    product.name,
                    style: AppTypography.h5(
                      color: AppColors.foreground(context),
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Extra info bubble (unit/quantity/multiplier)
                  if (product.formattedExtraInfo != null)
                    _ExtraInfoBubble(
                      text: product.formattedExtraInfo!,
                      storeType: product.storeType,
                    ),
                  if (product.formattedExtraInfo != null)
                    const SizedBox(height: AppSpacing.sm),

                  // Price section (large, prominent, with strikethrough next to it)
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

/// Product image section with store type badge
class _ProductImageSection extends StatelessWidget {
  final MiniAppProduct product;

  const _ProductImageSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1, // Square image
      child: Stack(
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg - 1),
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

          // Store type badge (bottom right)
          if (product.storeType != null)
            Positioned(
              bottom: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: product.storeType!.color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  product.storeType!.displayName,
                  style: AppTypography.labelSmall(
                    color: Colors.white,
                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
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
                  style: AppTypography.caption(
                    color: Colors.white,
                  ).copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ),

          // Out of stock overlay
          if (!product.isInStock)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg - 1),
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
                    style: AppTypography.labelSmall(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.bold),
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
        size: 48,
        color: isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.grey.shade300,
      ),
    );
  }
}

/// Marquee text slider showing store name
class _StoreMarqueeSection extends StatelessWidget {
  final String storeName;
  final StoreType? storeType;

  const _StoreMarqueeSection({required this.storeName, this.storeType});

  @override
  Widget build(BuildContext context) {
    final color = storeType?.color ?? AppColors.themeRed;

    return Container(
      height: 24,
      width: double.infinity,
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: MarqueeText(
        text: storeName,
        velocity: 25.0,
        spacing: 60.0,
        style: AppTypography.labelSmall(
          color: color,
        ).copyWith(fontWeight: FontWeight.w600, height: 1.0),
      ),
    );
  }
}

/// Extra info bubble showing unit/quantity/multiplier
class _ExtraInfoBubble extends StatelessWidget {
  final String text;
  final StoreType? storeType;

  const _ExtraInfoBubble({required this.text, this.storeType});

  @override
  Widget build(BuildContext context) {
    final color = storeType?.color ?? AppColors.foregroundMuted(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        text,
        style: AppTypography.caption(
          color: color,
        ).copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Price section with large current price and strikethrough original price
class _PriceSection extends StatelessWidget {
  final MiniAppProduct product;

  const _PriceSection({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Current price (large and red)
        Text(
          product.formattedCurrentPrice,
          style: AppTypography.h4(
            color: AppColors.themeRed,
          ).copyWith(fontWeight: FontWeight.bold),
        ),

        // Original price (strikethrough, next to current)
        if (product.hasDiscount) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            product.formattedOriginalPrice,
            style: AppTypography.bodySmall(
              color: AppColors.foregroundMuted(context),
            ).copyWith(decoration: TextDecoration.lineThrough),
          ),
        ],
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

    // If in cart, show quantity counter (oval shape)
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.themeRed.withValues(alpha: 0.15)
            : AppColors.themeRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
            isLeft: true,
          ),

          // Quantity display
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                style: AppTypography.labelLarge(
                  color: AppColors.themeRed,
                ).copyWith(fontWeight: FontWeight.bold),
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
            isLeft: false,
          ),
        ],
      ),
    );
  }
}

/// Oval "Add" button with cart icon
class _AddButton extends StatelessWidget {
  final MiniAppProduct product;
  final VoidCallback onAdd;

  const _AddButton({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = !product.isInStock;

    return GestureDetector(
      onTap: isDisabled ? null : onAdd,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
              : AppColors.themeRed,
          borderRadius: BorderRadius.circular(
            AppSpacing.radiusFull,
          ), // Oval shape
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
                Icons.shopping_cart_rounded, // Cart icon instead of add icon
                size: 18,
                color: isDisabled ? Colors.grey : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Add',
                style: AppTypography.buttonMedium(
                  color: isDisabled ? Colors.grey : Colors.white,
                ).copyWith(fontWeight: FontWeight.bold),
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
  final bool isLeft;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.transparent
              : AppColors.themeRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.horizontal(
            left: isLeft
                ? const Radius.circular(AppSpacing.radiusFull)
                : Radius.zero,
            right: isLeft
                ? Radius.zero
                : const Radius.circular(AppSpacing.radiusFull),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: isDisabled
                ? AppColors.themeRed.withValues(alpha: 0.4)
                : AppColors.themeRed,
          ),
        ),
      ),
    );
  }
}
