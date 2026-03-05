import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';
import '../../domain/models/product_model.dart';
import '../providers/mini_app_providers.dart';
import '../widgets/unified_product_card.dart';
import '../widgets/product_details_modal.dart';

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
  final String? collectionId;
  final String? subcollectionId;

  const BaseProductsScreen({
    super.key,
    required this.miniAppType,
    required this.subcategoryId,
    this.collectionId,
    this.subcollectionId,
  });
}

/// Base state for products screen
abstract class BaseProductsScreenState<T extends BaseProductsScreen>
    extends ConsumerState<T> {
  final ScrollController scrollController = ScrollController();
  double _borderRadius = 24.0;

  // Configuration for corner animation (consistent with mini-app home)
  static const double _maxRadius = 24.0;
  static const double _scrollThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollOffset = scrollController.offset;
    final newRadius =
        (_maxRadius - (scrollOffset / _scrollThreshold * _maxRadius)).clamp(
          0.0,
          _maxRadius,
        );

    if (newRadius != _borderRadius) {
      setState(() {
        _borderRadius = newRadius;
      });
    }
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
    return UnifiedProductCard(
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
      decoration: const BoxDecoration(color: AppColors.themeRed),
      child: ProductsHeader(
        title: title,
        productCount: productCount,
        onBack: () => context.pop(),
      ),
    );
  }

  /// Bottom padding for floating nav bar (extra space for bottom nav)
  double get bottomPadding => 140;

  //
  // HANDLERS
  //

  /// Handle quantity changes in cart
  void handleQuantityChanged(MiniAppProduct product, int quantity) {
    if (quantity == 0) {
      ref
          .read(miniAppCartNotifierProvider(widget.miniAppType))
          .removeProduct(product.id);
    } else {
      ref
          .read(miniAppCartNotifierProvider(widget.miniAppType))
          .addProduct(product, quantity);
    }
  }

  /// Handle product tap - shows product details modal
  void handleProductTap(MiniAppProduct product) {
    // Get current cart quantity for this product
    final cartQuantity = ref.read(
      productCartQuantityProvider((
        miniAppType: widget.miniAppType,
        productId: product.id,
      )),
    );

    // Show product details modal
    ProductDetailsModal.show(
      context: context,
      product: product,
      cartQuantity: cartQuantity,
      onQuantityChanged: (quantity) => handleQuantityChanged(product, quantity),
      onBuyNow: () {
        // TODO: Implement buy now flow
        Navigator.of(context).pop();
      },
    );
  }

  //
  // SHARED IMPLEMENTATION
  //

  MiniAppSubcategory? getSubcategory() {
    final selectedCategoryId = ref.read(
      selectedCategoryIdProvider(widget.miniAppType),
    );
    final subcategoriesAsync = ref.read(
      miniAppSubcategoriesProvider((
        miniAppType: widget.miniAppType,
        categoryId: selectedCategoryId,
      )),
    );
    final subcategories = subcategoriesAsync.value ?? [];

    if (subcategories.isEmpty) return null;

    try {
      return subcategories.firstWhere((s) => s.id == widget.subcategoryId);
    } catch (_) {
      return MiniAppSubcategory(
        id: '',
        name: 'Products',
        categoryId: '',
        imageUrl: null,
        productCount: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subcategory = getSubcategory();
    final selectedStore = ref.watch(selectedStoreProvider(widget.miniAppType));

    // Choose the right provider depending on whether a collection or
    // subcollection filter was supplied (3rd/4th-tier navigation).
    final AsyncValue<List<MiniAppProduct>> productsAsync;
    if (widget.subcollectionId != null) {
      productsAsync = ref.watch(
        miniAppSubcollectionProductsProvider((
          miniAppType: widget.miniAppType,
          storeId: selectedStore?.id,
          subcategoryId: widget.subcategoryId,
          subcollectionId: widget.subcollectionId!,
        )),
      );
    } else if (widget.collectionId != null) {
      productsAsync = ref.watch(
        miniAppCollectionProductsProvider((
          miniAppType: widget.miniAppType,
          storeId: selectedStore?.id,
          subcategoryId: widget.subcategoryId,
          collectionId: widget.collectionId!,
        )),
      );
    } else {
      productsAsync = ref.watch(
        miniAppProductsProvider((
          miniAppType: widget.miniAppType,
          storeId: selectedStore?.id,
          subcategoryId: widget.subcategoryId,
        )),
      );
    }

    // Return content directly without nested Scaffold
    // MiniAppShell provides the outer Scaffold with bottomNavigationBar
    // This ensures modal sheets appear above the bottom nav bar
    return Container(
      color: AppColors.themeRed,
      child: Column(
        children: [
          // SLOT: Header (on red background)
          buildHeader(
            context,
            subcategory?.name ?? 'Products',
            productsAsync.value?.length ?? 0,
          ),

          // SHARED: Content area with animated rounded corners
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF121212)
                    : AppColors.neutralWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_borderRadius),
                  topRight: Radius.circular(_borderRadius),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_borderRadius),
                  topRight: Radius.circular(_borderRadius),
                ),
                child: productsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.themeRed),
                  ),
                  error: (error, _) => buildEmptyState(context),
                  data: (products) => products.isEmpty
                      ? buildEmptyState(context)
                      : buildProductsGrid(context, products),
                ),
              ),
            ),
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

  Widget buildProductsGrid(
    BuildContext context,
    List<MiniAppProduct> products,
  ) {
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
        final cartQuantity = ref.watch(
          productCartQuantityProvider((
            miniAppType: widget.miniAppType,
            productId: product.id,
          )),
        );

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
          // Back button (no background)
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title only (no product count)
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
