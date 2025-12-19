import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/theme.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/cart_model.dart';
import '../providers/mini_app_providers.dart';

/// Cart screen for mini-apps
/// Shows cart items with quantity controls and checkout popup
class MiniAppCartScreen extends ConsumerWidget {
  final MiniAppType miniAppType;

  const MiniAppCartScreen({
    super.key,
    required this.miniAppType,
  });

  void _handleClose(BuildContext context) {
    context.go('/home');
  }

  void _showCheckoutPopup(BuildContext context, WidgetRef ref) {
    final cart = ref.read(miniAppCartProvider(miniAppType));
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final cart = ref.watch(miniAppCartProvider(miniAppType));
    final isEmpty = cart.items.isEmpty;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: const BoxDecoration(
              color: AppColors.themeRed,
            ),
            child: _CartHeader(
              itemCount: cart.totalItems,
              onClose: () => _handleClose(context),
            ),
          ),
          
          // Cart content
          Expanded(
            child: isEmpty
                ? _buildEmptyState(context)
                : _buildCartList(context, ref, cart),
          ),
          
          // Checkout bar
          if (!isEmpty)
            _CheckoutBar(
              cart: cart,
              onCheckout: () => _showCheckoutPopup(context, ref),
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
            onTap: () => context.go('/mini-app/${miniAppType.name}/home'),
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

  Widget _buildCartList(BuildContext context, WidgetRef ref, MiniAppCart cart) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
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

/// Cart header
class _CartHeader extends StatelessWidget {
  final int itemCount;
  final VoidCallback onClose;

  const _CartHeader({
    required this.itemCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Cart',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$itemCount items',
                  style: AppTypography.caption(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          
          // Close button
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
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
        bottom: bottomPadding + AppSpacing.md + 70, // Account for floating nav
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
