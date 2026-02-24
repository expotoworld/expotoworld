import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/product_model.dart';

/// Product details modal - draggable bottom sheet with image carousel
///
/// Shows product images in an auto-playing carousel with:
/// - Horizontal swipe navigation
/// - Image counter (1/10, 2/10, etc.)
/// - Pinch-to-zoom with full-screen viewer on tap
/// - Product details, pricing, and add-to-cart actions
class ProductDetailsModal extends StatefulWidget {
  final MiniAppProduct product;
  final int cartQuantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onClose;
  final VoidCallback? onBuyNow;

  const ProductDetailsModal({
    super.key,
    required this.product,
    required this.cartQuantity,
    required this.onQuantityChanged,
    required this.onClose,
    this.onBuyNow,
  });

  /// Show the product details modal
  static void show({
    required BuildContext context,
    required MiniAppProduct product,
    required int cartQuantity,
    required ValueChanged<int> onQuantityChanged,
    VoidCallback? onBuyNow,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useRootNavigator: true,
      builder: (context) => ProductDetailsModal(
        product: product,
        cartQuantity: cartQuantity,
        onQuantityChanged: onQuantityChanged,
        onClose: () => Navigator.pop(context),
        onBuyNow: onBuyNow,
      ),
    );
  }

  @override
  State<ProductDetailsModal> createState() => _ProductDetailsModalState();
}

class _ProductDetailsModalState extends State<ProductDetailsModal> {
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  // Local cart quantity state
  late int _localQuantity;

  // Flag to prevent multiple close calls
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _localQuantity = widget.cartQuantity;
  }

  @override
  void dispose() {
    _draggableController.dispose();
    super.dispose();
  }

  void _updateQuantity(int newQuantity) {
    setState(() => _localQuantity = newQuantity);
    widget.onQuantityChanged(newQuantity);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate min/max sizes leaving space for tap-to-close
    const double minSize = 0.70; // Initial size showing image
    const double maxSize = 0.87; // Max size leaving ~8% for tap-to-close

    return GestureDetector(
      // Tap outside to close (the area above the sheet)
      onTap: () {
        if (!_isClosing) {
          _isClosing = true;
          widget.onClose();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: DraggableScrollableSheet(
        controller: _draggableController,
        initialChildSize: minSize,
        minChildSize: 0.5, // Allow dragging down to close
        maxChildSize: maxSize,
        snap: true,
        snapSizes: const [minSize, maxSize],
        builder: (context, scrollController) {
          return NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              // Close modal when dragged down below threshold (only once)
              if (notification.extent <= 0.52 && !_isClosing) {
                _isClosing = true;
                widget.onClose();
              }
              return true;
            },
            child: GestureDetector(
              // Prevent tap propagation to parent (don't close when tapping sheet)
              onTap: () {},
              // NOTE: Using Container without background for the image area
              // The image carousel handles its own background to avoid anti-aliasing artifacts
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Stack(
                    children: [
                      // Background container for content area (below image)
                      // This covers only the product info and action bar area
                      Positioned.fill(
                        child: Container(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.95)
                              : Colors.white.withValues(alpha: 0.98),
                        ),
                      ),
                      // Main content
                      Column(
                        children: [
                          // Scrollable content
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              padding: EdgeInsets.zero,
                              children: [
                                // Image carousel - handles its own clipping internally
                                _ProductImageCarousel(product: widget.product),

                                // Product info
                                Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: _ProductInfoSection(
                                    product: widget.product,
                                  ),
                                ),

                                // Extra spacing for action bar
                                SizedBox(height: 100 + bottomPadding),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Overlay header (drag handle + close button on top of image)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _OverlayHeader(
                          onClose: () {
                            if (!_isClosing) {
                              _isClosing = true;
                              widget.onClose();
                            }
                          },
                        ),
                      ),

                      // Sticky action bar at bottom
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _StickyActionBar(
                          product: widget.product,
                          quantity: _localQuantity,
                          onQuantityChanged: _updateQuantity,
                          onBuyNow: widget.onBuyNow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Overlay header with drag handle and close button (transparent, on top of image)
class _OverlayHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _OverlayHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        // Subtle gradient for visibility
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle at the very top (with small top padding)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Row with spacer and close button
            SizedBox(
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Close button on right
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
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

/// Product image carousel with auto-play and counter
class _ProductImageCarousel extends StatefulWidget {
  final MiniAppProduct product;

  const _ProductImageCarousel({required this.product});

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  // Mock multiple images for demo (in production, product would have image list)
  // Always show 5 images for demo regardless of whether product has imageUrl
  List<String?> get _images {
    // For demo purposes, always generate 5 "images" (real or placeholder)
    // In production, this would come from product.images list
    return List.generate(5, (_) => widget.product.imageUrl);
  }

  // Virtual infinite scroll for auto-play
  static const int _virtualPageCount = 10000;
  int get _initialPage => _images.length > 1
      ? (_virtualPageCount ~/ 2) - ((_virtualPageCount ~/ 2) % _images.length)
      : 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
    if (_images.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _images.length > 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _pauseAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  void _resumeAutoPlay() {
    if (_images.length > 1) {
      _autoPlayTimer?.cancel();
      _startAutoPlay();
    }
  }

  void _openFullScreenViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(images: _images, initialIndex: index);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in ClipRRect to handle top corner clipping independently
    // This prevents anti-aliasing artifacts from the parent container
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
      child: AspectRatio(
        aspectRatio: 1, // Square carousel
        child: Stack(
          children: [
            // Image PageView
            GestureDetector(
              onPanDown: (_) => _pauseAutoPlay(),
              onPanEnd: (_) => _resumeAutoPlay(),
              onPanCancel: () => _resumeAutoPlay(),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = _images.length > 1
                        ? index % _images.length
                        : 0;
                  });
                },
                itemCount: _images.length > 1 ? _virtualPageCount : 1,
                itemBuilder: (context, index) {
                  final actualIndex = _images.length > 1
                      ? index % _images.length
                      : 0;
                  return GestureDetector(
                    onTap: () => _openFullScreenViewer(actualIndex),
                    child: _ProductImage(
                      imageUrl: _images[actualIndex],
                      colorIndex: actualIndex,
                    ),
                  );
                },
              ),
            ),

            // Image counter (bottom right)
            if (_images.length > 1)
              Positioned(
                bottom: AppSpacing.md,
                right: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${_currentPage + 1}/${_images.length}',
                    style: AppTypography.caption(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            // Low stock indicator
            if (widget.product.stockLeft <= 5 && widget.product.stockLeft > 0)
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Only ${widget.product.stockLeft} left',
                    style: AppTypography.caption(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // Out of stock overlay
            if (!widget.product.isInStock)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      'Out of Stock',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Single product image with placeholder (colored variants for demo)
class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final int colorIndex;

  const _ProductImage({this.imageUrl, this.colorIndex = 0});

  // Placeholder colors for demo - distinct pastel colors
  static const List<Color> _placeholderColors = [
    Color(0xFFFFE5E5), // Light red/pink
    Color(0xFFE5F0FF), // Light blue
    Color(0xFFE5FFE5), // Light green
    Color(0xFFFFF5E5), // Light orange
    Color(0xFFF5E5FF), // Light purple
  ];

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        _placeholderColors[colorIndex % _placeholderColors.length];

    return Container(
      color: placeholderColor,
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholder(placeholderColor),
            )
          : _buildPlaceholder(placeholderColor),
    );
  }

  Widget _buildPlaceholder(Color bgColor) {
    // Calculate icon color based on background brightness
    final iconColor = HSLColor.fromColor(
      bgColor,
    ).withLightness(0.4).withSaturation(0.6).toColor();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_rounded,
            size: 80,
            color: iconColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Image ${colorIndex + 1}',
            style: AppTypography.caption(
              color: iconColor.withValues(alpha: 0.7),
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Full-screen image viewer with pinch-to-zoom
class _FullScreenImageViewer extends StatefulWidget {
  final List<String?> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Zoomable image viewer
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              // Reset zoom when changing pages
              _transformController.value = Matrix4.identity();
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: widget.images[index] != null
                      ? Image.network(
                          widget.images[index]!,
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          Icons.shopping_basket_rounded,
                          size: 120,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                ),
              );
            },
          ),

          // Close button (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.md,
            right: AppSpacing.md,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Image counter (bottom center)
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.images.length}',
                    style: AppTypography.bodyMedium(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Product info section with name, description, price
class _ProductInfoSection extends StatelessWidget {
  final MiniAppProduct product;

  const _ProductInfoSection({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name
        Text(
          product.name,
          style: AppTypography.h3(
            color: AppColors.foreground(context),
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Store type badge + Store name (if available)
        if (product.storeName != null || product.storeType != null) ...[
          Row(
            children: [
              // Store type badge
              if (product.storeType != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: product.storeType!.color,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    product.storeType!.displayName,
                    style: AppTypography.labelSmall(
                      color: Colors.white,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Icon(
                Icons.store_rounded,
                size: 16,
                color: AppColors.foregroundMuted(context),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  product.storeName ?? 'Unknown Store',
                  style: AppTypography.bodySmall(
                    color: AppColors.foregroundMuted(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Price section (no discount badge)
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Current price (large and red)
            Text(
              product.formattedCurrentPrice,
              style: AppTypography.h2(
                color: AppColors.themeRed,
              ).copyWith(fontWeight: FontWeight.bold),
            ),

            // Original price (strikethrough) - no discount badge
            if (product.hasDiscount) ...[
              const SizedBox(width: AppSpacing.md),
              Text(
                product.formattedOriginalPrice,
                style: AppTypography.bodyLarge(
                  color: AppColors.foregroundMuted(context),
                ).copyWith(decoration: TextDecoration.lineThrough),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Extra info (unit/quantity/multiplier)
        if (product.formattedExtraInfo != null) ...[
          _InfoBubble(
            text: product.formattedExtraInfo!,
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Shelf location
        if (product.shelfCode != null && product.shelfCode!.isNotEmpty) ...[
          _InfoBubble(
            text: 'Shelf: ${product.shelfCode}',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Stock indicator
        _InfoBubble(
          text: product.isInStock
              ? '${product.stockLeft} in stock'
              : 'Out of stock',
          icon: product.isInStock
              ? Icons.check_circle_outline_rounded
              : Icons.cancel_outlined,
          color: product.isInStock ? AppColors.green : AppColors.themeRed,
        ),

        // Divider
        const SizedBox(height: AppSpacing.xl),
        Divider(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Description
        Text(
          'Description',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.foreground(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          product.description,
          style: AppTypography.bodyMedium(
            color: AppColors.foregroundMuted(context),
          ),
        ),
      ],
    );
  }
}

/// Info bubble with icon and text
class _InfoBubble extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const _InfoBubble({required this.text, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = color ?? AppColors.foregroundMuted(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bubbleColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: bubbleColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTypography.caption(
              color: bubbleColor,
            ).copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Sticky action bar with Add to Cart / Quantity Counter + Buy Now
class _StickyActionBar extends StatelessWidget {
  final MiniAppProduct product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onBuyNow;

  const _StickyActionBar({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    this.onBuyNow,
  });

  void _handleBuyNow(BuildContext context) {
    // Get the quantity to purchase (if in cart, use that; otherwise use MOQ or 1)
    final purchaseQuantity = quantity > 0
        ? quantity
        : (product.minimumOrderQuantity > 1 ? product.minimumOrderQuantity : 1);

    // Show the Buy Now checkout popup
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (modalContext) => _BuyNowCheckoutPopup(
        product: product,
        quantity: purchaseQuantity,
        onConfirm: () {
          // Close the checkout popup
          Navigator.pop(modalContext);
          // Close the product details modal
          Navigator.pop(context);
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Order placed for ${product.name}!',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isInCart = quantity > 0;

    return Padding(
      // Exact same padding as bottom nav bar
      padding: EdgeInsets.only(
        left: AppSpacing.xxl,
        right: AppSpacing.xxl,
        bottom: bottomPadding > 5 ? bottomPadding - 5 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // MOQ warning (if applicable)
          if (product.showMoq && !isInCart)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.yellow,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Minimum order: ${product.minimumOrderQuantity} units',
                      style: AppTypography.caption(
                        color: AppColors.yellow,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

          // Floating action bar - EXACT same style as bottom nav bar
          Container(
            height: 70, // Exact same height as bottom nav bar
            decoration: BoxDecoration(
              // Solid semi-transparent background without backdrop blur - no artifacts
              color: isDark
                  ? const Color(0xEE1C1C1E) // Dark gray, mostly opaque
                  : const Color(0xF5FFFFFF), // White, mostly opaque
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, // 8px horizontal padding inside pill
                vertical: AppSpacing
                    .sm, // 8px vertical to center 54px buttons in 70px bar
              ),
              child: Row(
                children: [
                  // Buy Now button (now on left) - opens checkout popup
                  Expanded(
                    flex: 3, // Smaller proportion for Buy Now
                    child: _BuyNowButton(
                      onPressed: product.isInStock
                          ? () => _handleBuyNow(context)
                          : null,
                    ),
                  ),

                  const SizedBox(
                    width: AppSpacing.sm,
                  ), // Small gap between buttons
                  // Add to Cart / Quantity Counter (now on right)
                  Expanded(
                    flex: 5, // Larger proportion for Add to Cart
                    child: isInCart
                        ? _QuantityCounter(
                            quantity: quantity,
                            product: product,
                            onQuantityChanged: onQuantityChanged,
                          )
                        : _AddToCartButton(
                            product: product,
                            onPressed: product.isInStock
                                ? () {
                                    HapticFeedback.lightImpact();
                                    final startQty =
                                        product.minimumOrderQuantity > 1
                                        ? product.minimumOrderQuantity
                                        : 1;
                                    onQuantityChanged(startQty);
                                  }
                                : null,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Add to Cart button
class _AddToCartButton extends StatefulWidget {
  final MiniAppProduct product;
  final VoidCallback? onPressed;

  const _AddToCartButton({required this.product, this.onPressed});

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 54, // Sized to fit within 70px action bar
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade400 : AppColors.themeRed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.themeRed.withValues(
                      alpha: _isPressed ? 0.2 : 0.3,
                    ),
                    blurRadius: _isPressed ? 6 : 8,
                    offset: Offset(0, _isPressed ? 1 : 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_rounded,
              size: 20,
              color: isDisabled ? Colors.grey.shade600 : Colors.white,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Add to Cart',
              style: AppTypography.buttonMedium(
                color: isDisabled ? Colors.grey.shade600 : Colors.white,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// Buy Now button (outlined style)
class _BuyNowButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _BuyNowButton({this.onPressed});

  @override
  State<_BuyNowButton> createState() => _BuyNowButtonState();
}

class _BuyNowButtonState extends State<_BuyNowButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 54, // Sized to fit within 70px action bar
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.transparent
              : (isDark
                    ? Colors.white.withValues(alpha: _isPressed ? 0.08 : 0.05)
                    : Colors.black.withValues(alpha: _isPressed ? 0.08 : 0.05)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isDisabled ? Colors.grey.shade400 : AppColors.themeRed,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            'Buy Now',
            style: AppTypography.buttonMedium(
              color: isDisabled ? Colors.grey.shade400 : AppColors.themeRed,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/// Quantity counter (when item is in cart)
class _QuantityCounter extends StatelessWidget {
  final int quantity;
  final MiniAppProduct product;
  final ValueChanged<int> onQuantityChanged;

  const _QuantityCounter({
    required this.quantity,
    required this.product,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 54, // Sized to fit within 70px action bar
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
          _CounterActionButton(
            icon: quantity <= product.minimumOrderQuantity
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              final newQty = quantity - 1;
              if (newQty < product.minimumOrderQuantity) {
                onQuantityChanged(0);
              } else {
                onQuantityChanged(newQty);
              }
            },
            isLeft: true,
          ),

          // Quantity display (just the number, no "in cart" text)
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.themeRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Increase button
          _CounterActionButton(
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

/// Counter action button (+/-)
class _CounterActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLeft;

  const _CounterActionButton({
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
        width: 54, // Match container height for circular ends
        height: 54,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.transparent
              : AppColors.themeRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.horizontal(
            left: isLeft
                ? const Radius.circular(27) // Half of 54 for perfect semicircle
                : Radius.zero,
            right: isLeft
                ? Radius.zero
                : const Radius.circular(
                    27,
                  ), // Half of 54 for perfect semicircle
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 24,
            color: isDisabled
                ? AppColors.themeRed.withValues(alpha: 0.4)
                : AppColors.themeRed,
          ),
        ),
      ),
    );
  }
}

/// Buy Now checkout popup - single item quick checkout
class _BuyNowCheckoutPopup extends StatefulWidget {
  final MiniAppProduct product;
  final int quantity;
  final VoidCallback onConfirm;

  const _BuyNowCheckoutPopup({
    required this.product,
    required this.quantity,
    required this.onConfirm,
  });

  @override
  State<_BuyNowCheckoutPopup> createState() => _BuyNowCheckoutPopupState();
}

class _BuyNowCheckoutPopupState extends State<_BuyNowCheckoutPopup> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _totalPrice => widget.product.currentPrice * widget.quantity;

  void _handleConfirm() async {
    // Basic validation
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    // Simulate processing
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isProcessing = false);
      widget.onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  'Quick Checkout',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.foreground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.foregroundMuted(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Scrollable form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary (single item)
                  _BuyNowOrderSummary(
                    product: widget.product,
                    quantity: widget.quantity,
                    totalPrice: _totalPrice,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Contact info section
                  _BuyNowSectionTitle(title: 'Contact Information'),
                  const SizedBox(height: AppSpacing.md),
                  _BuyNowTextField(
                    controller: _nameController,
                    label: 'Full Name *',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BuyNowTextField(
                    controller: _emailController,
                    label: 'Email *',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BuyNowTextField(
                    controller: _phoneController,
                    label: 'Phone *',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Delivery address
                  _BuyNowSectionTitle(title: 'Delivery Address'),
                  const SizedBox(height: AppSpacing.md),
                  _BuyNowTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Payment method
                  _BuyNowSectionTitle(title: 'Payment Method'),
                  const SizedBox(height: AppSpacing.md),
                  _BuyNowPaymentSelector(
                    selected: _selectedPaymentMethod,
                    onChanged: (method) {
                      setState(() => _selectedPaymentMethod = method);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Confirm button
          Container(
            padding: EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: bottomPadding + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              children: [
                // Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: AppTypography.caption(
                          color: AppColors.foregroundMuted(context),
                        ),
                      ),
                      Text(
                        '€${_totalPrice.toStringAsFixed(2)}',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.foreground(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Confirm button
                GestureDetector(
                  onTap: _isProcessing ? null : _handleConfirm,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: _isProcessing ? Colors.grey : AppColors.themeRed,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      boxShadow: _isProcessing
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.themeRed.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isProcessing) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Processing...',
                            style: AppTypography.labelMediumStyle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.flash_on_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Confirm Order',
                            style: AppTypography.labelMediumStyle.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Order summary for Buy Now checkout
class _BuyNowOrderSummary extends StatelessWidget {
  final MiniAppProduct product;
  final int quantity;
  final double totalPrice;

  const _BuyNowOrderSummary({
    required this.product,
    required this.quantity,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.themeRed.withValues(alpha: 0.1)
            : AppColors.themeRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.themeRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on_rounded, size: 20, color: AppColors.themeRed),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Quick Buy',
                style: AppTypography.labelMediumStyle.copyWith(
                  color: AppColors.themeRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                '${quantity}x',
                style: AppTypography.caption(
                  color: AppColors.foregroundMuted(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  product.name,
                  style: AppTypography.bodySmall(
                    color: AppColors.foreground(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '€${totalPrice.toStringAsFixed(2)}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.themeRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section title for Buy Now checkout
class _BuyNowSectionTitle extends StatelessWidget {
  final String title;

  const _BuyNowSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.labelMediumStyle.copyWith(
        color: AppColors.foreground(context),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Text field for Buy Now checkout
class _BuyNowTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _BuyNowTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTypography.bodyMedium(color: AppColors.foreground(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall(
          color: AppColors.foregroundMuted(context),
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.foregroundMuted(context),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.themeRed),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
      ),
    );
  }
}

/// Payment method selector for Buy Now checkout
class _BuyNowPaymentSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _BuyNowPaymentSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        _PaymentOption(
          id: 'card',
          icon: Icons.credit_card_rounded,
          label: 'Card',
          isSelected: selected == 'card',
          onTap: () => onChanged('card'),
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.md),
        _PaymentOption(
          id: 'cash',
          icon: Icons.money_rounded,
          label: 'Cash',
          isSelected: selected == 'cash',
          onTap: () => onChanged('cash'),
          isDark: isDark,
        ),
        const SizedBox(width: AppSpacing.md),
        _PaymentOption(
          id: 'twint',
          icon: Icons.qr_code_rounded,
          label: 'TWINT',
          isSelected: selected == 'twint',
          onTap: () => onChanged('twint'),
          isDark: isDark,
        ),
      ],
    );
  }
}

/// Single payment option button
class _PaymentOption extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _PaymentOption({
    required this.id,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.themeRed.withValues(alpha: 0.1)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppColors.themeRed
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? AppColors.themeRed
                    : AppColors.foregroundMuted(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.caption(
                  color: isSelected
                      ? AppColors.themeRed
                      : AppColors.foregroundMuted(context),
                ).copyWith(fontWeight: isSelected ? FontWeight.bold : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
