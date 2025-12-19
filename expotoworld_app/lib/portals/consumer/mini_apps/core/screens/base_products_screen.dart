import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';
import '../../domain/models/product_model.dart';
import '../../data/mock_data.dart';
import '../providers/mini_app_providers.dart';
import '../widgets/product_card.dart';

/// Abstract base class for mini-app products screen
/// Implements the shared functionality with slots for customization
/// 
/// Customization slots:
/// - [buildProductCard] - Build individual product card (override for MOQ, reviews, etc.)
/// - [buildHeader] - Build the header section
/// - [bottomPadding] - Space at bottom (for floating nav)
abstract class BaseProductsScreen extends ConsumerStatefulWidget {
  final MiniAppType miniAppType;
  final String subcategoryId;

  const BaseProductsScreen({
    super.key,
    required this.miniAppType,
    required this.subcategoryId,
  });
}

/// Base state for products screen
abstract class BaseProductsScreenState<T extends BaseProductsScreen>
    extends ConsumerState<T> {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  //
  // CUSTOMIZATION SLOTS
  //

  /// Build individual product card
  /// Override to customize product display (MOQ badges, review stars, etc.)
  Widget buildProductCard(
    BuildContext context,
    MiniAppProduct product,
    int cartQuantity,
  ) {
    return MiniAppProductCard(
      product: product,
      cartQuantity: cartQuantity,
      onQuantityChanged: (quantity) => handleQuantityChanged(product, quantity),
      onTap: () => handleProductTap(product),
    );
  }

  /// Build the header section
  /// Default implementation with back button
  Widget buildHeader(BuildContext context, String title, int productCount) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Container(
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: const BoxDecoration(
        color: AppColors.themeRed,
      ),
      child: ProductsHeader(
        title: title,
        productCount: productCount,
        onBack: () => context.pop(),
      ),
    );
  }

  /// Bottom padding for floating nav bar
  double get bottomPadding => AppSpacing.lg;

  //
  // HANDLERS
  //

  /// Handle quantity changes in cart
  void handleQuantityChanged(MiniAppProduct product, int quantity) {
    if (quantity == 0) {
      ref.read(miniAppCartNotifierProvider(widget.miniAppType))
          .removeProduct(product.id);
    } else {
      ref.read(miniAppCartNotifierProvider(widget.miniAppType))
          .addProduct(product, quantity);
    }
  }

  /// Handle product tap
  void handleProductTap(MiniAppProduct product) {
    // Override in subclass for product detail navigation
  }

  //
  // SHARED IMPLEMENTATION
  //

  MiniAppSubcategory? getSubcategory() {
    final subcategories = widget.miniAppType == MiniAppType.toX
        ? MiniAppMockData.serviceSubcategories
        : MiniAppMockData.productSubcategories;

    return subcategories.firstWhere(
      (s) => s.id == widget.subcategoryId,
      orElse: () => MiniAppSubcategory(
        id: '',
        name: 'Products',
        categoryId: '',
        imageUrl: null,
        productCount: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subcategory = getSubcategory();
    final selectedStore = ref.watch(selectedStoreProvider(widget.miniAppType));
    final products = ref.watch(miniAppProductsProvider((
      miniAppType: widget.miniAppType,
      storeId: selectedStore?.id,
      subcategoryId: widget.subcategoryId,
    )));

    return Scaffold(
      body: Column(
        children: [
          // SLOT: Header
          buildHeader(context, subcategory?.name ?? 'Products', products.length),

          // SHARED: Products grid
          Expanded(
            child: products.isEmpty
                ? buildEmptyState(context)
                : buildProductsGrid(context, products),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.foregroundMuted(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No products available',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.foreground(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Check back later for updates',
            style: AppTypography.bodySmall(
              color: AppColors.foregroundMuted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductsGrid(BuildContext context, List<MiniAppProduct> products) {
    return MasonryGridView.count(
      controller: scrollController,
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        bottomPadding,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final cartQuantity = ref.watch(productCartQuantityProvider((
          miniAppType: widget.miniAppType,
          productId: product.id,
        )));

        return buildProductCard(context, product, cartQuantity);
      },
    );
  }
}

/// Shared header widget for products screen
class ProductsHeader extends StatelessWidget {
  final String title;
  final int productCount;
  final VoidCallback onBack;
  final VoidCallback? onFilter;

  const ProductsHeader({
    super.key,
    required this.title,
    required this.productCount,
    required this.onBack,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title and count
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$productCount products',
                  style: AppTypography.caption(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Filter button
          if (onFilter != null)
            GestureDetector(
              onTap: onFilter,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
