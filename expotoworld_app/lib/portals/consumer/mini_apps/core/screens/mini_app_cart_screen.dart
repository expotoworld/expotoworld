import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/providers/locale_provider.dart';
import '../../../../../shared/widgets/language_flag.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/cart_model.dart';
import '../providers/mini_app_providers.dart';

/// Cart screen for mini-apps
/// Shows cart items with quantity controls and checkout popup
class MiniAppCartScreen extends ConsumerStatefulWidget {
  final MiniAppType miniAppType;

  const MiniAppCartScreen({
    super.key,
    required this.miniAppType,
  });

  @override
  ConsumerState<MiniAppCartScreen> createState() => _MiniAppCartScreenState();
}

class _MiniAppCartScreenState extends ConsumerState<MiniAppCartScreen> {
  final ScrollController _scrollController = ScrollController();
  double _borderRadius = 24.0;
  
  // Configuration for the corner animation
  static const double _maxRadius = 24.0;
  static const double _scrollThreshold = 50.0; // Flatten within 50px of scroll
  
  MiniAppType get miniAppType => widget.miniAppType;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;
    final newRadius = (_maxRadius - (scrollOffset / _scrollThreshold * _maxRadius))
        .clamp(0.0, _maxRadius);
    
    if (newRadius != _borderRadius) {
      setState(() {
        _borderRadius = newRadius;
      });
    }
  }

  void _handleClose(BuildContext context) {
    // Use rootNavigator to ensure proper vertical slide-down animation.
    // With StatefulShellRoute, the navigation stack is preserved when switching
    // between tabs, so rootNavigator.canPop() will be true.
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }
    
    // Fallback to standard pop
    if (context.canPop()) {
      context.pop();
      return;
    }

    // Absolute failsafe (only if opened directly via deep link with no history)
    context.go('/');
  }

  void _showCheckoutPopup(BuildContext context) {
    final cart = ref.read(miniAppCartProvider(miniAppType));
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true, // Show above bottom navigation bar
      builder: (context) => _CheckoutPopup(
        miniAppType: miniAppType,
        cart: cart,
        onConfirm: () {
          // Clear cart and close popup
          ref.read(miniAppCartNotifierProvider(miniAppType)).clearCart();
          Navigator.pop(context);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Order placed successfully!'),
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
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = ref.watch(miniAppCartProvider(miniAppType));
    final isEmpty = cart.items.isEmpty;

    // Return content directly without nested Scaffold
    // MiniAppShell provides the outer Scaffold with bottomNavigationBar
    // This ensures modal sheets appear above the bottom nav bar
    return Container(
      color: AppColors.themeRed,
      child: Column(
        children: [
          // Fixed header - stays at top while content scrolls
          Container(
            padding: EdgeInsets.only(top: statusBarHeight),
            color: AppColors.themeRed,
            child: _CartHeader(
              itemCount: cart.totalItems,
              onClose: () => _handleClose(context),
            ),
          ),
          
          // Scrollable content area with dynamic rounded top corners
          Expanded(
            child: Stack(
              children: [
                // Main content with curved top
                AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : AppColors.neutralWhite,
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
                    child: isEmpty
                        ? _buildEmptyState(context)
                        : _buildCartList(context, cart),
                  ),
                ),
                
                // Checkout bar pinned to bottom
                if (!isEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _CheckoutBar(
                      cart: cart,
                      onCheckout: () => _showCheckoutPopup(context),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.themeRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppColors.themeRed.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your cart is empty',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.foreground(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add products to get started',
            style: AppTypography.bodySmall(
              color: AppColors.foregroundMuted(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GestureDetector(
            onTap: () {
              // Switch to home tab (index 0) using the shared provider
              ref.read(miniAppActiveTabIndexProvider(miniAppType).notifier).state = 0;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.themeRed,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                'Browse Products',
                style: AppTypography.labelMediumStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(BuildContext context, MiniAppCart cart) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Checkout bar height: ~80px base + bottomPadding + some extra space
    final checkoutBarSpace = 80 + bottomPadding + AppSpacing.lg;
    
    return ListView.builder(
      controller: _scrollController,
      // Add bottom padding for checkout bar
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xl, // More space between header divider and first card
        bottom: checkoutBarSpace, // Dynamic space for checkout bar
      ),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return _CartItemCard(
          item: item,
          onQuantityChanged: (quantity) {
            if (quantity == 0) {
              ref.read(miniAppCartNotifierProvider(miniAppType))
                  .removeProduct(item.product.id);
            } else {
              ref.read(miniAppCartNotifierProvider(miniAppType))
                  .updateQuantity(item.product.id, quantity);
            }
          },
          onRemove: () {
            ref.read(miniAppCartNotifierProvider(miniAppType))
                .removeProduct(item.product.id);
          },
        );
      },
    );
  }
}

/// Cart header - matches super-app header style
/// With language toggle on left, centered logo + "My Cart" title, close button on right
class _CartHeader extends ConsumerWidget {
  final int itemCount;
  final VoidCallback onClose;

  const _CartHeader({
    required this.itemCount,
    required this.onClose,
  });

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true, // Show above bottom navigation bar
      builder: (context) => _LanguagePickerSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final currentLang = AppLanguage.values.firstWhere(
      (lang) => lang.locale.languageCode == currentLocale.languageCode,
      orElse: () => AppLanguage.english,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main header row
        SizedBox(
          height: AppSpacing.appBarHeight,
          child: Stack(
            children: [
              // Center - Logo and "My Cart" title side by side (horizontal layout)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Block logo (same as super-app header)
                    SvgPicture.asset(
                      'assets/logo/block.svg',
                      height: 32,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFF8F9FA), // Off-white
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // "My Cart" text next to the logo
                    Text(
                      'MY CART',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700, // Extra bold
                      ),
                    ),
                  ],
                ),
              ),
              // Left side - Language toggle
              Positioned(
                left: AppSpacing.lg,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _showLanguagePicker(context, ref),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LanguageFlag(
                            language: currentLang,
                            size: 35,
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Right side - Close button (no background)
              Positioned(
                right: AppSpacing.lg,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: onClose,
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Search bar (same as mini-app home header)
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.xs,
            bottom: AppSpacing.md,
          ),
          child: _CartSearchBar(),
        ),
      ],
    );
  }
}

/// Search bar for cart (same style as mini-app home)
class _CartSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to search
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Search products...',
              style: AppTypography.bodySmall(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual cart item card
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = item.product;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: Container(
              width: 80,
              height: 80,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.shopping_basket_rounded,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                    )
                  : Icon(
                      Icons.shopping_basket_rounded,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTypography.labelMediumStyle.copyWith(
                    color: AppColors.foreground(context),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.weight,
                  style: AppTypography.caption(
                    color: AppColors.foregroundMuted(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // Price
                Row(
                  children: [
                    Text(
                      product.formattedCurrentPrice,
                      style: AppTypography.labelMediumStyle.copyWith(
                        color: AppColors.themeRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        product.formattedOriginalPrice,
                        style: AppTypography.caption(
                          color: AppColors.foregroundMuted(context),
                        ).copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // Quantity controls
                Row(
                  children: [
                    _QuantityControl(
                      quantity: item.quantity,
                      minQuantity: product.minimumOrderQuantity,
                      maxQuantity: product.stockLeft,
                      onChanged: onQuantityChanged,
                    ),
                    const Spacer(),
                    // Item total
                    Text(
                      '€${item.totalPrice.toStringAsFixed(2)}',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.foreground(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Remove button
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.foregroundMuted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quantity control widget
class _QuantityControl extends StatelessWidget {
  final int quantity;
  final int minQuantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  const _QuantityControl({
    required this.quantity,
    required this.minQuantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              final newQty = quantity - 1;
              if (newQty < minQuantity) {
                onChanged(0); // Remove from cart
              } else {
                onChanged(newQty);
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusSm),
                ),
              ),
              child: Icon(
                quantity <= minQuantity
                    ? Icons.delete_outline_rounded
                    : Icons.remove_rounded,
                size: 18,
                color: AppColors.themeRed,
              ),
            ),
          ),
          
          // Quantity
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            child: Center(
              child: Text(
                '$quantity',
                style: AppTypography.labelMediumStyle.copyWith(
                  color: AppColors.foreground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Increase
          GestureDetector(
            onTap: quantity < maxQuantity
                ? () {
                    HapticFeedback.lightImpact();
                    onChanged(quantity + 1);
                  }
                : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AppSpacing.radiusSm),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 18,
                color: quantity < maxQuantity
                    ? AppColors.themeRed
                    : AppColors.foregroundMuted(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Checkout bar at bottom
class _CheckoutBar extends StatelessWidget {
  final MiniAppCart cart;
  final VoidCallback onCheckout;

  const _CheckoutBar({
    required this.cart,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        // Compact bottom: just above the floating nav bar
        bottom: bottomPadding > 0 ? bottomPadding + 10 : 1,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E)
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total info
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
                  '€${cart.totalPrice.toStringAsFixed(2)}',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.foreground(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Checkout button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onCheckout();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.themeRed,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.themeRed.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Checkout',
                    style: AppTypography.labelMediumStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

/// Single-page checkout popup
class _CheckoutPopup extends StatefulWidget {
  final MiniAppType miniAppType;
  final MiniAppCart cart;
  final VoidCallback onConfirm;

  const _CheckoutPopup({
    required this.miniAppType,
    required this.cart,
    required this.onConfirm,
  });

  @override
  State<_CheckoutPopup> createState() => _CheckoutPopupState();
}

class _CheckoutPopupState extends State<_CheckoutPopup> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
                  'Checkout',
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
                  // Order summary
                  _OrderSummaryCard(cart: widget.cart),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Contact info section
                  _SectionTitle(title: 'Contact Information'),
                  const SizedBox(height: AppSpacing.md),
                  _CheckoutTextField(
                    controller: _nameController,
                    label: 'Full Name *',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CheckoutTextField(
                    controller: _emailController,
                    label: 'Email *',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CheckoutTextField(
                    controller: _phoneController,
                    label: 'Phone *',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Delivery address
                  _SectionTitle(title: 'Delivery Address'),
                  const SizedBox(height: AppSpacing.md),
                  _CheckoutTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Payment method
                  _SectionTitle(title: 'Payment Method'),
                  const SizedBox(height: AppSpacing.md),
                  _PaymentMethodSelector(
                    selected: _selectedPaymentMethod,
                    onChanged: (method) {
                      setState(() => _selectedPaymentMethod = method);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Notes
                  _SectionTitle(title: 'Order Notes (Optional)'),
                  const SizedBox(height: AppSpacing.md),
                  _CheckoutTextField(
                    controller: _notesController,
                    label: 'Any special instructions?',
                    icon: Icons.note_outlined,
                    maxLines: 3,
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
            child: GestureDetector(
              onTap: _isProcessing ? null : _handleConfirm,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: _isProcessing
                      ? AppColors.themeRed.withValues(alpha: 0.7)
                      : AppColors.themeRed,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.themeRed.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Confirm Order • €${widget.cart.totalPrice.toStringAsFixed(2)}',
                              style: AppTypography.labelMediumStyle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

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

class _CheckoutTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _CheckoutTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: AppTypography.bodyMedium(
          color: AppColors.foreground(context),
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: AppTypography.bodyMedium(
            color: AppColors.foregroundMuted(context),
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: AppColors.foregroundMuted(context),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final MiniAppCart cart;

  const _OrderSummaryCard({required this.cart});

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
        border: Border.all(
          color: AppColors.themeRed.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 20,
                color: AppColors.themeRed,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Order Summary',
                style: AppTypography.labelMediumStyle.copyWith(
                  color: AppColors.themeRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...cart.items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Text(
                  '${item.quantity}x',
                  style: AppTypography.caption(
                    color: AppColors.foregroundMuted(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    item.product.name,
                    style: AppTypography.bodySmall(
                      color: AppColors.foreground(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '€${item.totalPrice.toStringAsFixed(2)}',
                  style: AppTypography.bodySmall(
                    color: AppColors.foreground(context),
                  ),
                ),
              ],
            ),
          )),
          if (cart.items.length > 3)
            Text(
              '+${cart.items.length - 3} more items',
              style: AppTypography.caption(
                color: AppColors.foregroundMuted(context),
              ),
            ),
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (${cart.totalItems} items)',
                style: AppTypography.labelMediumStyle.copyWith(
                  color: AppColors.foreground(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '€${cart.totalPrice.toStringAsFixed(2)}',
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

class _PaymentMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PaymentMethodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PaymentOption(
            value: 'card',
            label: 'Card',
            icon: Icons.credit_card_rounded,
            isSelected: selected == 'card',
            onTap: () => onChanged('card'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _PaymentOption(
            value: 'cash',
            label: 'Cash',
            icon: Icons.payments_rounded,
            isSelected: selected == 'cash',
            onTap: () => onChanged('cash'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _PaymentOption(
            value: 'apple',
            label: 'Apple Pay',
            icon: Icons.apple,
            isSelected: selected == 'apple',
            onTap: () => onChanged('apple'),
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.themeRed.withValues(alpha: 0.1)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.themeRed
                : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
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
                    : AppColors.foreground(context),
              ).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Language picker bottom sheet (matches super-app ExpoAppBar pattern)
class _LanguagePickerSheet extends StatelessWidget {
  final WidgetRef ref;

  const _LanguagePickerSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
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
              Text(
                'Select Language',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Language options - scrollable
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: bottomPadding + AppSpacing.lg),
                  itemCount: AppLanguage.values.length,
                  itemBuilder: (context, index) {
                    final lang = AppLanguage.values[index];
                    final isSelected = currentLocale.languageCode == lang.locale.languageCode;
                    return _buildLanguageOption(
                      context: context,
                      lang: lang,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () {
                        ref.read(localeProvider.notifier).setLocale(lang.locale);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required AppLanguage lang,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.themeRed.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: isSelected
              ? Border.all(color: AppColors.themeRed.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            LanguageFlag(
              language: lang,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.nativeName,
                    style: AppTypography.bodyMedium().copyWith(
                      color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    lang.englishName,
                    style: AppTypography.bodySmall().copyWith(
                      color: isDark
                          ? AppColors.neutralGray400
                          : AppColors.neutralGray600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.themeRed,
                size: AppSpacing.iconMd,
              ),
          ],
        ),
      ),
    );
  }
}
