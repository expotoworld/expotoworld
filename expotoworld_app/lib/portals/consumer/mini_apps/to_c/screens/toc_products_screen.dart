import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screens/base_products_screen.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/product_model.dart';
import '../../core/widgets/product_card.dart';

/// toC Products Screen - Business to Consumer
/// 
/// Customizations specific to toC:
/// - Consumer reviews/ratings display
/// - Wishlist heart button
/// - Social sharing options
/// - Recently viewed
class ToCProductsScreen extends BaseProductsScreen {
  const ToCProductsScreen({
    super.key,
    required super.subcategoryId,
  }) : super(miniAppType: MiniAppType.toC);

  @override
  ConsumerState<ToCProductsScreen> createState() => _ToCProductsScreenState();
}

class _ToCProductsScreenState extends BaseProductsScreenState<ToCProductsScreen> {
  @override
  Widget buildProductCard(
    BuildContext context,
    MiniAppProduct product,
    int cartQuantity,
  ) {
    // Currently using default product card
    // Override to add reviews, wishlist, etc.
    return MiniAppProductCard(
      product: product,
      cartQuantity: cartQuantity,
      onQuantityChanged: (quantity) => handleQuantityChanged(product, quantity),
      onTap: () => handleProductTap(product),
    );
    
    // FUTURE: Use toC-specific product card with reviews
    // return ToCProductCard(
    //   product: product,
    //   cartQuantity: cartQuantity,
    //   showReviews: true,
    //   showWishlist: true,
    //   onQuantityChanged: (quantity) => handleQuantityChanged(product, quantity),
    // );
  }
}
