import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/product.dart';
import '../../../core/enums/store_type.dart';
import '../../../core/utils/mini_app_navigation.dart';
import '../../../data/services/product_data_resolver.dart';
import 'add_to_cart_button.dart';
import 'product_tag.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final String? categoryName;
  final String? subcategoryName;
  final String? storeName;
  final bool isInHotRecommendations;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.categoryName,
    this.subcategoryName,
    this.storeName,
    this.isInHotRecommendations = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap ?? () => _handleProductTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, 12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrls.isNotEmpty 
                        ? product.imageUrls.first 
                        : 'https://placehold.co/300x300/E2E8F0/6A7485?text=No+Image', // Fallback URL
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.lightRed,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.themeRed,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.lightRed,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppColors.themeRed,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),

              // Product Title
              Text(
                product.title,
                style: AppTextStyles.responsiveCardTitle(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),

              // Product Description
              Text(
                product.descriptionShort,
                style: AppTextStyles.responsiveBodySmall(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // FIX: Stock Info (only for unmanned stores and warehouses)
              if (product.storeType == StoreType.unmannedStore || product.storeType == StoreType.unmannedWarehouse) ...[
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 4)),
                Text(
                  '剩余 ${product.displayStock ?? 0} 件', // Use ?? 0 to handle null gracefully
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.themeRed,
                  ),
                ),
              ],

              // Product Tags (positioned above pricing)
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 6)),
              _buildProductTags(context),

              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
              
              // Price and Add Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Price Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.strikethroughPrice != null)
                          Text(
                            '€${product.strikethroughPrice!.toStringAsFixed(2)}',
                            style: AppTextStyles.responsiveBodySmall(context).copyWith(
                              color: AppColors.secondaryText,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          '€${product.mainPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.responsivePriceMain(context),
                        ),
                      ],
                    ),
                  ),
                  
                  // Add to Cart Button
                  AddToCartButton(
                    product: product,
                    isInHotRecommendations: isInHotRecommendations,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProductTap(BuildContext context) async {
    if (isInHotRecommendations) {
      // For hot recommendations, navigate to mini-app and show modal
      MiniAppNavigation.showProductDetailsWithMiniAppBackground(
        context,
        product,
        categoryName: categoryName,
        subcategoryName: subcategoryName,
        storeName: storeName,
      );
    } else {
      // Normal behavior: show product details modal
      _showProductDetails(context);
    }
  }

  void _showProductDetails(BuildContext context) async {
    debugPrint('🔍 ProductCard: Showing details for product ${product.id} (${product.title})');
    debugPrint('🔍 ProductCard: Initial data - Category: $categoryName, Subcategory: $subcategoryName, Store: $storeName');

    // If category/subcategory/store names are not provided, resolve them from the backend
    String? resolvedCategoryName = categoryName;
    String? resolvedSubcategoryName = subcategoryName;
    String? resolvedStoreName = storeName;

    // Always resolve missing data for consistent tag display
    final needsResolution = resolvedCategoryName == null ||
                           resolvedSubcategoryName == null ||
                           (product.storeType == StoreType.unmannedStore ||
                            product.storeType == StoreType.unmannedWarehouse ||
                            product.storeType == StoreType.exhibitionStore ||
                            product.storeType == StoreType.exhibitionMall) && resolvedStoreName == null;

    debugPrint('🔍 ProductCard: Needs resolution: $needsResolution');

    if (needsResolution) {
      try {
        debugPrint('🔍 ProductCard: Calling ProductDataResolver...');
        final resolver = ProductDataResolver();
        final productData = await resolver.resolveProductData(product);

        resolvedCategoryName ??= productData.categoryName;
        resolvedSubcategoryName ??= productData.subcategoryName;
        resolvedStoreName ??= productData.storeName;

        debugPrint('🔍 ProductCard: After resolution - Category: $resolvedCategoryName, Subcategory: $resolvedSubcategoryName, Store: $resolvedStoreName');
      } catch (e) {
        debugPrint('🔍 ProductCard: Error resolving product data: $e');
        // Continue with null values if resolution fails
      }
    }

    // Check if widget is still mounted before using context
    if (!context.mounted) return;

    debugPrint('🔍 ProductCard: No onTap callback provided, product details cannot be shown');
    debugPrint('🔍 ProductCard: Product ${product.id} (${product.title}) requires parent widget to handle product details display');
    // Note: This method should not be called when onTap is null
    // All ProductCard instances should now provide an onTap callback
  }

  /// Builds product tags using the same styling as ProductDetailsModal
  Widget _buildProductTags(BuildContext context) {
    final tags = <Widget>[];

    // Category tag
    if (categoryName != null && categoryName!.isNotEmpty) {
      tags.add(ProductTag(
        text: categoryName!,
        type: ProductTagType.category,
        size: ProductTagSize.small, // Use small size for product cards
      ));
    }

    // Subcategory tag
    if (subcategoryName != null && subcategoryName!.isNotEmpty) {
      tags.add(ProductTag(
        text: subcategoryName!,
        type: ProductTagType.subcategory,
        size: ProductTagSize.small, // Use small size for product cards
      ));
    }

    // Store location and store type tags (only for location-dependent mini-apps)
    if (_shouldShowStoreTag() && storeName != null && storeName!.isNotEmpty) {
      // Extract store name from formatted string (e.g., "无人门店: MANOR Lugano" -> "MANOR Lugano")
      String storeLocationName = storeName!;
      if (storeName!.contains(': ')) {
        storeLocationName = storeName!.split(': ').last;
      }

      tags.add(ProductTag(
        text: storeLocationName,
        type: ProductTagType.storeLocation,
        storeType: product.storeType,
        size: ProductTagSize.small, // Use small size for product cards
      ));

      // Add store type tag as a separate tag
      tags.add(ProductTag(
        text: product.storeType.displayName,
        type: ProductTagType.storeType,
        storeType: product.storeType,
        size: ProductTagSize.small, // Use small size for product cards
      ));
    }

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
      runSpacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
      children: tags,
    );
  }

  /// Determines if store tags should be shown based on store type
  bool _shouldShowStoreTag() {
    return product.storeType == StoreType.unmannedStore ||
           product.storeType == StoreType.unmannedWarehouse ||
           product.storeType == StoreType.exhibitionStore ||
           product.storeType == StoreType.exhibitionMall;
  }
}