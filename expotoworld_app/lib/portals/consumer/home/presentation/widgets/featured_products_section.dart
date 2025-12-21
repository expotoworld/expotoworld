import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme.dart';
import '../../../mini_apps/data/mock_data.dart';
import '../../../mini_apps/core/widgets/unified_product_card.dart';

/// Featured products section with masonry waterfall grid layout
class FeaturedProductsSection extends StatefulWidget {
  const FeaturedProductsSection({super.key});

  @override
  State<FeaturedProductsSection> createState() => _FeaturedProductsSectionState();
}

class _FeaturedProductsSectionState extends State<FeaturedProductsSection> {
  // Track cart quantities locally for demo (in production, use provider)
  final Map<String, int> _cartQuantities = {};

  @override
  Widget build(BuildContext context) {
    // Get recommended products from the MEGA store (default for super-app home)
    final megaStore = MiniAppMockData.megaStores.first;
    final featuredProducts = MiniAppMockData.getRecommendedProducts(megaStore.id)
        .take(6)
        .toList(); // Show first 6 products

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
        
        // Masonry waterfall grid layout (natural height based on content)
        MasonryGridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          padding: EdgeInsets.zero,
          itemCount: featuredProducts.length,
          itemBuilder: (context, index) {
            final product = featuredProducts[index];
            return UnifiedProductCard(
              product: product,
              cartQuantity: _cartQuantities[product.id] ?? 0,
              onQuantityChanged: (qty) {
                setState(() {
                  if (qty == 0) {
                    _cartQuantities.remove(product.id);
                  } else {
                    _cartQuantities[product.id] = qty;
                  }
                });
              },
              // onTap is null, so it will open the ProductDetailsModal by default
            );
          },
        ),
      ],
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
