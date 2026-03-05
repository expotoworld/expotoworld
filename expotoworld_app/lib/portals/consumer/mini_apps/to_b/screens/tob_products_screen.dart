import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/screens/base_products_screen.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/product_model.dart';
import '../../core/widgets/unified_product_card.dart';

/// toB Products Screen - Business to Business
///
/// Customizations specific to toB:
/// - MOQ badge on product cards
/// - Bulk discount indicators
/// - B2B pricing tiers
class ToBProductsScreen extends BaseProductsScreen {
  const ToBProductsScreen({
    super.key,
    required super.subcategoryId,
    super.collectionId,
    super.subcollectionId,
  }) : super(miniAppType: MiniAppType.toB);

  @override
  ConsumerState<ToBProductsScreen> createState() => _ToBProductsScreenState();
}

class _ToBProductsScreenState
    extends BaseProductsScreenState<ToBProductsScreen> {
  @override
  Widget buildProductCard(
    BuildContext context,
    MiniAppProduct product,
    int cartQuantity,
  ) {
    // Using unified product card design
    // TODO: Add MOQ badge, bulk pricing as overlay or additional element if needed
    return UnifiedProductCard(
      product: product,
      cartQuantity: cartQuantity,
      onQuantityChanged: (quantity) => handleQuantityChanged(product, quantity),
      onTap: () => handleProductTap(product),
    );
  }
}
