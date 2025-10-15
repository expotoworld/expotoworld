import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/product.dart';
import '../../../core/enums/store_type.dart';
import 'product_tag.dart';
import 'product_action_bar.dart';

/// Universal product details modal that can be used across all product interactions
class ProductDetailsModal extends StatefulWidget {
  final Product product;
  final String? categoryName;
  final String? subcategoryName;
  final String? storeName;
  final VoidCallback onClose;

  const ProductDetailsModal({
    super.key,
    required this.product,
    required this.onClose,
    this.categoryName,
    this.subcategoryName,
    this.storeName,
  });

  @override
  State<ProductDetailsModal> createState() => _ProductDetailsModalState();
}

class _ProductDetailsModalState extends State<ProductDetailsModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late DraggableScrollableController _draggableController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _draggableController = DraggableScrollableController();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _draggableController.dispose();
    super.dispose();
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background dimming overlay
        Container(
          color: Colors.black.withValues(alpha: 0.5), // Static background
          child: GestureDetector(
            onTap: _closeModal, // Close when tapping outside
            child: Container(), // Empty container to capture taps
          ),
        ),
        // Modal content with slide animation
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on modal content
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(_animation),
              child: NotificationListener<DraggableScrollableNotification>(
                    onNotification: (notification) {
                      // Close modal when dragged down below minimum threshold
                      if (notification.extent <= 0.45) {
                        _closeModal();
                      }
                      return true;
                    },
                    child: DraggableScrollableSheet(
                      controller: _draggableController,
                      initialChildSize: 0.7,
                      minChildSize: 0.5,
                      maxChildSize: 0.85, // Reduced from 0.95 to leave space for navigation bar
                      snap: true,
                      snapSizes: const [0.5, 0.7, 0.85], // Updated snap sizes
                      builder: (context, scrollController) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Handle bar and close button
                              _buildHeader(),

                              // Scrollable content
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  padding: EdgeInsets.all(
                                    ResponsiveUtils.getResponsiveSpacing(context, 16),
                                  ),
                                  child: _buildContent(),
                                ),
                              ),

                              // Sticky action bar at the bottom
                              ProductActionBar(product: widget.product),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        left: ResponsiveUtils.getResponsiveSpacing(context, 16),
        right: ResponsiveUtils.getResponsiveSpacing(context, 16),
        top: ResponsiveUtils.getResponsiveSpacing(context, 8),
        bottom: ResponsiveUtils.getResponsiveSpacing(context, 4), // Reduced bottom padding
      ),
      child: Row(
        children: [
          // Handle bar (centered)
          Expanded(
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Close button
          GestureDetector(
            onTap: _closeModal,
            child: Container(
              padding: const EdgeInsets.all(6), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 18, // Slightly smaller icon
                color: AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        _buildProductImage(),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 12)), // Reduced from 16

        // Product Name
        _buildProductName(),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)), // Reduced from 12

        // Pricing and Stock Row
        _buildPricingAndStockRow(),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 12)), // Reduced from 16

        // Product Tags
        _buildProductTags(),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 12)), // Reduced from 16

        // Product Description
        _buildProductDescription(),
      ],
    );
  }

  Widget _buildProductImage() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.product.imageUrls.isNotEmpty
              ? widget.product.imageUrls.first
              : 'https://placehold.co/300x300/E2E8F0/6A7485?text=No+Image',
          fit: BoxFit.contain, // Show full image without cropping
          placeholder: (context, url) => Container(
            color: AppColors.lightRed,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.themeRed,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.lightBackground,
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: AppColors.secondaryText,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductName() {
    return Text(
      widget.product.title,
      style: AppTextStyles.responsiveCardTitle(context),
    );
  }

  Widget _buildPricingAndStockRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Pricing Section (left-aligned)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.product.strikethroughPrice != null)
                Text(
                  '€${widget.product.strikethroughPrice!.toStringAsFixed(2)}',
                  style: AppTextStyles.responsiveBodySmall(context).copyWith(
                    color: AppColors.secondaryText,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                '€${widget.product.mainPrice.toStringAsFixed(2)}',
                style: AppTextStyles.responsivePriceMain(context),
              ),
            ],
          ),
        ),
        
        // Stock Information (right-aligned, for 无人商店 only)
        if (_shouldShowStock()) _buildStockInfo(),
      ],
    );
  }

  bool _shouldShowStock() {
    return widget.product.storeType == StoreType.unmannedStore ||
           widget.product.storeType == StoreType.unmannedWarehouse;
  }

  Widget _buildStockInfo() {
    final displayStock = widget.product.displayStock ?? 0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context, 12),
        vertical: ResponsiveUtils.getResponsiveSpacing(context, 6),
      ),
      decoration: BoxDecoration(
        color: AppColors.lightRed,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.themeRed.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        '库存: $displayStock',
        style: AppTextStyles.responsiveBodySmall(context).copyWith(
          color: AppColors.themeRed,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProductTags() {
    debugPrint('🔍 ProductDetailsModal: Building tags for product ${widget.product.id}');
    debugPrint('🔍 ProductDetailsModal: Category: ${widget.categoryName}');
    debugPrint('🔍 ProductDetailsModal: Subcategory: ${widget.subcategoryName}');
    debugPrint('🔍 ProductDetailsModal: Store: ${widget.storeName}');
    debugPrint('🔍 ProductDetailsModal: Should show store tag: ${_shouldShowStoreTag()}');
    debugPrint('🔍 ProductDetailsModal: Product store type: ${widget.product.storeType}');

    final tags = <Widget>[];

    // Category tag
    if (widget.categoryName != null && widget.categoryName!.isNotEmpty) {
      debugPrint('🔍 ProductDetailsModal: Adding category tag: ${widget.categoryName}');
      tags.add(ProductTag(
        text: widget.categoryName!,
        type: ProductTagType.category,
      ));
    } else {
      debugPrint('🔍 ProductDetailsModal: No category name provided');
    }

    // Subcategory tag
    if (widget.subcategoryName != null && widget.subcategoryName!.isNotEmpty) {
      debugPrint('🔍 ProductDetailsModal: Adding subcategory tag: ${widget.subcategoryName}');
      tags.add(ProductTag(
        text: widget.subcategoryName!,
        type: ProductTagType.subcategory,
      ));
    } else {
      debugPrint('🔍 ProductDetailsModal: No subcategory name provided');
    }

    // Store location and store type tags (only for location-dependent mini-apps)
    if (_shouldShowStoreTag() && widget.storeName != null && widget.storeName!.isNotEmpty) {
      // Extract store name from formatted string (e.g., "无人门店: MANOR Lugano" -> "MANOR Lugano")
      String storeLocationName = widget.storeName!;
      if (widget.storeName!.contains(': ')) {
        storeLocationName = widget.storeName!.split(': ').last;
      }

      debugPrint('🔍 ProductDetailsModal: Adding store location tag: $storeLocationName');
      tags.add(ProductTag(
        text: storeLocationName,
        type: ProductTagType.storeLocation,
        storeType: widget.product.storeType,
      ));

      // Add store type tag as a separate tag
      debugPrint('🔍 ProductDetailsModal: Adding store type tag: ${widget.product.storeType.displayName}');
      tags.add(ProductTag(
        text: widget.product.storeType.displayName,
        type: ProductTagType.storeType,
        storeType: widget.product.storeType,
      ));
    } else {
      debugPrint('🔍 ProductDetailsModal: No store location tag needed or no store name provided');
    }

    debugPrint('🔍 ProductDetailsModal: Total tags created: ${tags.length}');

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
      runSpacing: ResponsiveUtils.getResponsiveSpacing(context, 8),
      children: tags,
    );
  }

  bool _shouldShowStoreTag() {
    return widget.product.storeType == StoreType.unmannedStore ||
           widget.product.storeType == StoreType.unmannedWarehouse ||
           widget.product.storeType == StoreType.exhibitionStore ||
           widget.product.storeType == StoreType.exhibitionMall;
  }

  Widget _buildProductDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '商品描述',
          style: AppTextStyles.responsiveCardTitle(context),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 6)), // Reduced from 8
        Text(
          widget.product.descriptionLong.isNotEmpty
              ? widget.product.descriptionLong
              : widget.product.descriptionShort.isNotEmpty
                  ? widget.product.descriptionShort
                  : '暂无商品描述',
          style: AppTextStyles.responsiveBody(context),
        ),
      ],
    );
  }
}


