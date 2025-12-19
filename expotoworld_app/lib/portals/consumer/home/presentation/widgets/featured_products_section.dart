import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme.dart';

/// Featured products section with masonry grid layout
class FeaturedProductsSection extends StatelessWidget {
  const FeaturedProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          AppLocalizations.of(context)!.homeRecommendedProducts,
          style: AppTypography.h3(
            color: AppColors.foreground(context),
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Masonry grid layout
        MasonryGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          padding: EdgeInsets.zero, // Remove default padding
          itemCount: _dummyProducts.length,
          itemBuilder: (context, index) {
            final product = _dummyProducts[index];
            return ProductCard(
              product: product,
              // Alternate heights for masonry effect
              imageHeight: index % 3 == 0 ? 160.0 : (index % 3 == 1 ? 120.0 : 140.0),
            );
          },
        ),
      ],
    );
  }
}

/// Product card widget for masonry grid
class ProductCard extends StatefulWidget {
  final Product product;
  final double imageHeight;

  const ProductCard({
    super.key,
    required this.product,
    this.imageHeight = 120,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = widget.product;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // TODO: NEED TO FULLY IMPLEMENT - Navigate to product detail
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.98 : 1.0)
          ..translate(0.0, _isPressed ? 2.0 : 0.0),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkBackgroundElevated.withValues(alpha: 0.6)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: AppShadows.card(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Container(
              height: widget.imageHeight,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image_rounded,
                  size: 48,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.15),
                ),
              ),
            ),
            
            // Product info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: AppTypography.bodySmall(
                      color: AppColors.foreground(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Price
                  Text(
                    product.formattedPrice,
                    style: AppTypography.priceMedium(
                      color: AppColors.themeRed,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  
                  // Manufacturer
                  Text(
                    product.manufacturer,
                    style: AppTypography.caption(
                      color: AppColors.foregroundMuted(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Product shimmer loading placeholder
class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: 160,
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
    );
  }
}

// TODO: DUMMY DATA
class Product {
  final String id;
  final String name;
  final double price;
  final String manufacturer;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.manufacturer,
    this.imageUrl,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
}

// TODO: DUMMY DATA
final List<Product> _dummyProducts = [
  Product(
    id: '1',
    name: 'Premium Wireless Headphones',
    price: 299.99,
    manufacturer: 'AudioTech Pro',
  ),
  Product(
    id: '2',
    name: 'Smart Home Hub',
    price: 149.99,
    manufacturer: 'HomeConnect',
  ),
  Product(
    id: '3',
    name: 'Portable Power Bank 20000mAh',
    price: 49.99,
    manufacturer: 'PowerMax',
  ),
  Product(
    id: '4',
    name: 'Ergonomic Office Chair',
    price: 599.99,
    manufacturer: 'ComfortPlus',
  ),
  Product(
    id: '5',
    name: 'Organic Green Tea Set',
    price: 29.99,
    manufacturer: 'TeaMaster',
  ),
];
