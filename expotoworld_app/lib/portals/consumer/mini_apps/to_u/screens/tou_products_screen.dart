import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screens/base_products_screen.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/product_model.dart';
import '../../core/widgets/unified_product_card.dart';

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
    super.collectionId,
  }) : super(miniAppType: MiniAppType.toU);

  @override
  ConsumerState<ToUProductsScreen> createState() => _ToUProductsScreenState();
}

class _ToUProductsScreenState
    extends BaseProductsScreenState<ToUProductsScreen> {
  @override
  Widget buildProductCard(
    BuildContext context,
    MiniAppProduct product,
    int cartQuantity,
  ) {
    // Using unified product card design
    // TODO: Add volume tiers, loyalty points as overlay or additional element if needed
    return UnifiedProductCard(
      product: product,
      cartQuantity: cartQuantity,
      onQuantityChanged: (quantity) => handleQuantityChanged(product, quantity),
      onTap: () => handleProductTap(product),
    );
  }
}
