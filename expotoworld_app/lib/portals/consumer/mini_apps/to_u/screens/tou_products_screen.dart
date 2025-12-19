import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screens/base_products_screen.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/product_model.dart';
import '../../core/widgets/product_card.dart';

/// toU Products Screen - Business to User (Volume-based)
/// 
/// Customizations specific to toU:
/// - Volume tier pricing display
/// - Usage-based discounts
/// - Subscription pricing options
/// - Loyalty points display
class ToUProductsScreen extends BaseProductsScreen {
  const ToUProductsScreen({
    super.key,
    required super.subcategoryId,
  }) : super(miniAppType: MiniAppType.toU);

  @override
  ConsumerState<ToUProductsScreen> createState() => _ToUProductsScreenState();
}

class _ToUProductsScreenState extends BaseProductsScreenState<ToUProductsScreen> {
  @override
  Widget buildProductCard(
    BuildContext context,
    MiniAppProduct product,
    int cartQuantity,
  ) {
    // Currently using default product card
    // Override to add volume tiers, loyalty points, etc.
    return MiniAppProductCard(
      product: product,
      cartQuantity: cartQuantity,
      onQuantityChanged: (quantity) => handleQuantityChanged(product, quantity),
      onTap: () => handleProductTap(product),
    );
    
    // FUTURE: Use toU-specific product card with volume tiers
    // return ToUProductCard(
    //   product: product,
    //   cartQuantity: cartQuantity,
    //   showVolumeTiers: true,
    //   showLoyaltyPoints: true,
    //   onQuantityChanged: (quantity) => handleQuantityChanged(product, quantity),
    // );
  }
}
