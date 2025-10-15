import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../core/enums/mini_app_type.dart';
import '../../presentation/screens/mini_apps/retail_store/retail_store_screen.dart';
import '../../presentation/screens/mini_apps/unmanned_store/unmanned_store_screen.dart';
import '../../presentation/screens/mini_apps/exhibition_sales/exhibition_sales_screen.dart';
import '../../presentation/screens/mini_apps/group_buying/group_buying_screen.dart';
import '../../presentation/screens/cart/cart_screen_wrapper.dart';

/// Utility class for handling navigation between mini-apps based on product types
class MiniAppNavigation {
  /// Navigate to the appropriate mini-app based on product's mini-app type
  static void navigateToMiniApp(BuildContext context, Product product) {
    Widget targetScreen;
    
    switch (product.miniAppType) {
      case MiniAppType.retailStore:
        targetScreen = const RetailStoreScreen();
        break;
      case MiniAppType.unmannedStore:
        targetScreen = UnmannedStoreScreen(
          instanceId: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        break;
      case MiniAppType.exhibitionSales:
        targetScreen = ExhibitionSalesScreen(
          instanceId: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        break;
      case MiniAppType.groupBuying:
        targetScreen = const GroupBuyingScreen();
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  /// Navigate to the cart screen of the appropriate mini-app
  static void navigateToMiniAppCart(BuildContext context, Product product) {
    switch (product.miniAppType) {
      case MiniAppType.retailStore:
        // For retail store, navigate to the mini-app with cart tab selected
        // Since we can't directly control the initial tab, navigate to mini-app
        navigateToMiniApp(context, product);
        break;
      case MiniAppType.unmannedStore:
        // For unmanned store, navigate to cart screen with wrapper
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => CartScreenWrapper(
            miniAppType: 'UnmannedStore',
            storeId: product.storeId != null ? int.tryParse(product.storeId!) : null,
          )),
        );
        break;
      case MiniAppType.exhibitionSales:
        // For exhibition sales, navigate to cart screen with wrapper
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => CartScreenWrapper(
            miniAppType: 'ExhibitionSales',
            storeId: product.storeId != null ? int.tryParse(product.storeId!) : null,
          )),
        );
        break;
      case MiniAppType.groupBuying:
        // For group buying, navigate to the mini-app (no separate cart)
        navigateToMiniApp(context, product);
        break;
    }
  }

  /// Show product details modal with mini-app background
  static void showProductDetailsWithMiniAppBackground(
    BuildContext context,
    Product product, {
    String? categoryName,
    String? subcategoryName,
    String? storeName,
  }) {
    // For hot recommendations, we need to navigate to the mini-app first
    // and then show the product details modal on top of it
    navigateToMiniApp(context, product);

    // Note: The actual product details modal will be shown by the mini-app
    // when it receives the product tap event. This method is primarily
    // for navigation to the correct mini-app context.
  }

  /// Check if a product belongs to location-dependent mini-apps
  static bool isLocationDependentMiniApp(MiniAppType miniAppType) {
    return miniAppType == MiniAppType.unmannedStore || 
           miniAppType == MiniAppType.exhibitionSales;
  }

  /// Get the display name for a mini-app type
  static String getMiniAppDisplayName(MiniAppType miniAppType) {
    return miniAppType.displayName;
  }
}
