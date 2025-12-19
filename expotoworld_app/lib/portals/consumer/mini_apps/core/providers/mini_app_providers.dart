import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/cart_model.dart';
import '../../data/mock_data.dart';

/// Provider for the currently selected mini-app type
final currentMiniAppTypeProvider = StateProvider<MiniAppType?>((ref) => null);

/// Provider for available stores based on mini-app type
final miniAppStoresProvider = Provider.family<List<MiniAppStore>, MiniAppType>((ref, miniAppType) {
  return MiniAppMockData.getStoresForMiniApp(miniAppType);
});

/// Provider for the selected store in a mini-app
final selectedStoreProvider = StateProvider.family<MiniAppStore?, MiniAppType>((ref, miniAppType) {
  final stores = ref.watch(miniAppStoresProvider(miniAppType));
  // Default to first store (closest by distance)
  return stores.isNotEmpty ? stores.first : null;
});

/// Provider for categories based on mini-app type
final miniAppCategoriesProvider = Provider.family<List<MiniAppCategory>, MiniAppType>((ref, miniAppType) {
  if (miniAppType == MiniAppType.toX) {
    return MiniAppMockData.serviceCategories;
  }
  return MiniAppMockData.productCategories;
});

/// Provider for the selected category ID
final selectedCategoryIdProvider = StateProvider.family<String?, MiniAppType>((ref, miniAppType) => null);

/// Provider for subcategories based on selected category
final miniAppSubcategoriesProvider = Provider.family<List<MiniAppSubcategory>, ({MiniAppType miniAppType, String? categoryId})>((ref, params) {
  if (params.miniAppType == MiniAppType.toX) {
    if (params.categoryId == null) {
      return MiniAppMockData.serviceSubcategories;
    }
    return MiniAppMockData.serviceSubcategories
        .where((sub) => sub.categoryId == params.categoryId)
        .toList();
  }
  
  if (params.categoryId == null) {
    return MiniAppMockData.productSubcategories;
  }
  return MiniAppMockData.productSubcategories
      .where((sub) => sub.categoryId == params.categoryId)
      .toList();
});

/// Provider for products based on mini-app type, store, and subcategory
final miniAppProductsProvider = Provider.family<List<MiniAppProduct>, ({
  MiniAppType miniAppType,
  String? storeId,
  String? subcategoryId,
})>((ref, params) {
  return MiniAppMockData.getProductsForSubcategory(
    params.subcategoryId ?? '',
    params.storeId ?? '',
  );
});

/// Provider for services (toX only)
final miniAppServicesProvider = Provider.family<List<MiniAppService>, ({String? subcategoryId})>((ref, params) {
  if (params.subcategoryId == null) return [];
  return MiniAppMockData.getServicesForSubcategory(params.subcategoryId!);
});

/// Mutable cart state map
final Map<MiniAppType, MiniAppCart> _cartStates = {};

/// Cart provider that exposes mutable cart state
final miniAppCartProvider = Provider.family<MiniAppCart, MiniAppType>((ref, miniAppType) {
  return _cartStates[miniAppType] ?? MiniAppCart.empty();
});

/// Cart notifier provider for mutations
final miniAppCartNotifierProvider = Provider.family<MiniAppCartController, MiniAppType>((ref, miniAppType) {
  return MiniAppCartController(miniAppType, ref);
});

/// Cart controller for mutations
class MiniAppCartController {
  final MiniAppType miniAppType;
  final Ref ref;

  MiniAppCartController(this.miniAppType, this.ref);

  MiniAppCart get state => _cartStates[miniAppType] ?? MiniAppCart.empty();

  void addProduct(MiniAppProduct product, int quantity) {
    _cartStates[miniAppType] = state.addProduct(product, quantity);
    ref.invalidate(miniAppCartProvider(miniAppType));
  }

  void updateQuantity(String productId, int quantity) {
    _cartStates[miniAppType] = state.updateQuantity(productId, quantity);
    ref.invalidate(miniAppCartProvider(miniAppType));
  }

  void removeProduct(String productId) {
    _cartStates[miniAppType] = state.removeProduct(productId);
    ref.invalidate(miniAppCartProvider(miniAppType));
  }

  int getQuantity(String productId) {
    return state.getQuantity(productId);
  }

  void clearCart() {
    _cartStates[miniAppType] = MiniAppCart.empty();
    ref.invalidate(miniAppCartProvider(miniAppType));
  }
}

/// Provider for cart item count (for badge display)
final miniAppCartItemCountProvider = Provider.family<int, MiniAppType>((ref, miniAppType) {
  final cart = ref.watch(miniAppCartProvider(miniAppType));
  return cart.totalItems;
});

/// Provider for cart total
final miniAppCartTotalProvider = Provider.family<double, MiniAppType>((ref, miniAppType) {
  final cart = ref.watch(miniAppCartProvider(miniAppType));
  return cart.totalPrice;
});

/// Provider to get quantity of a specific product in cart
final productCartQuantityProvider = Provider.family<int, ({MiniAppType miniAppType, String productId})>((ref, params) {
  final cart = ref.watch(miniAppCartProvider(params.miniAppType));
  return cart.getQuantity(params.productId);
});

/// Provider for recommended products (for "Recommended" category)
final recommendedProductsProvider = Provider.family<List<MiniAppProduct>, ({
  MiniAppType miniAppType,
  String? storeId,
})>((ref, params) {
  // Get all products for the store and return a subset as "recommended"
  final allProducts = MiniAppMockData.getProductsForSubcategory(
    '',  // All subcategories
    params.storeId ?? '',
  );
  
  // For demo, return first 12 products as recommended
  return allProducts.take(12).toList();
});

/// Provider for search query
final miniAppSearchQueryProvider = StateProvider.family<String, MiniAppType>((ref, miniAppType) => '');

/// Provider for filtered products based on search
final filteredProductsProvider = Provider.family<List<MiniAppProduct>, ({
  MiniAppType miniAppType,
  String? storeId,
  String? subcategoryId,
  String searchQuery,
})>((ref, params) {
  final products = MiniAppMockData.getProductsForSubcategory(
    params.subcategoryId ?? '',
    params.storeId ?? '',
  );
  
  if (params.searchQuery.isEmpty) {
    return products;
  }
  
  final query = params.searchQuery.toLowerCase();
  return products.where((product) {
    return product.name.toLowerCase().contains(query) ||
           product.description.toLowerCase().contains(query);
  }).toList();
});
