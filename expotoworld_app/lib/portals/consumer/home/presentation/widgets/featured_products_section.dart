import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme.dart';
import '../../../mini_apps/domain/enums/mini_app_type.dart';
import '../../../mini_apps/core/providers/mini_app_providers.dart';
import '../../../mini_apps/core/widgets/unified_product_card.dart';

/// Featured products section with masonry waterfall grid layout
class FeaturedProductsSection extends ConsumerStatefulWidget {
  const FeaturedProductsSection({super.key});

  @override
  ConsumerState<FeaturedProductsSection> createState() =>
      _FeaturedProductsSectionState();
}

class _FeaturedProductsSectionState
    extends ConsumerState<FeaturedProductsSection> {
  // Track cart quantities locally for demo (in production, use provider)
  final Map<String, int> _cartQuantities = {};

  @override
  Widget build(BuildContext context) {
    // Fetch featured/recommended products for the toC mini-app type (default for super-app home)
    final featuredAsync = ref.watch(
      recommendedProductsProvider((
        miniAppType: MiniAppType.toC,
        storeId: null,
      )),
    );

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

        // Handle async states
        featuredAsync.when(
          loading: () => MasonryGridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            padding: EdgeInsets.zero,
            itemCount: 4,
            itemBuilder: (_, __) => const ProductCardShimmer(),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (featuredProducts) {
            final products = featuredProducts.take(6).toList();
            if (products.isEmpty) return const SizedBox.shrink();

            return MasonryGridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              padding: EdgeInsets.zero,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
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
                );
              },
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
