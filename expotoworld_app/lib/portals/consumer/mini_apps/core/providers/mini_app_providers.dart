import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../../data/repositories/catalog_repository.dart';
import '../../domain/enums/mini_app_type.dart';
import '../../domain/models/store_model.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/cart_model.dart';

/// Provider for the currently selected mini-app type
final currentMiniAppTypeProvider = StateProvider<MiniAppType?>((ref) => null);

/// Provider for available stores based on mini-app type (async — API)
final miniAppStoresProvider =
    FutureProvider.family<List<MiniAppStore>, MiniAppType>((
      ref,
      miniAppType,
    ) async {
      final repo = ref.watch(catalogRepositoryProvider);
      return repo.getStores(miniAppType);
    });

/// Provider for the selected store in a mini-app.
///
/// Initialises to the first store once the async list resolves.
/// The user can change this via the UI, so it's a [StateProvider].
final selectedStoreProvider = StateProvider.family<MiniAppStore?, MiniAppType>((
  ref,
  miniAppType,
) {
  final storesAsync = ref.watch(miniAppStoresProvider(miniAppType));
  // Default to first store from the loaded list
  return storesAsync.value?.isNotEmpty == true
      ? storesAsync.value!.first
      : null;
});

/// Provider for categories based on mini-app type (async — API)
final miniAppCategoriesProvider =
    FutureProvider.family<List<MiniAppCategory>, MiniAppType>((
      ref,
      miniAppType,
    ) async {
      final repo = ref.watch(catalogRepositoryProvider);
      return repo.getCategories(miniAppType);
    });

/// Provider for the selected category ID
final selectedCategoryIdProvider = StateProvider.family<String?, MiniAppType>(
  (ref, miniAppType) => null,
);

/// Provider for subcategories based on selected category (async — API)
final miniAppSubcategoriesProvider =
    FutureProvider.family<
      List<MiniAppSubcategory>,
      ({MiniAppType miniAppType, String? categoryId})
    >((ref, params) async {
      final categoryId = params.categoryId;
      if (categoryId == null) return <MiniAppSubcategory>[];

      final repo = ref.watch(catalogRepositoryProvider);
      return repo.getSubcategories(int.parse(categoryId));
    });

/// Provider for collections based on selected subcategory (async — API)
final miniAppCollectionsProvider =
    FutureProvider.family<
      List<MiniAppCollection>,
      ({MiniAppType miniAppType, String subcategoryId})
    >((ref, params) async {
      final repo = ref.watch(catalogRepositoryProvider);
      return repo.getCollections(int.parse(params.subcategoryId));
    });

/// Provider for products based on mini-app type, store, and subcategory (async — API)
final miniAppProductsProvider =
    FutureProvider.family<
      List<MiniAppProduct>,
      ({MiniAppType miniAppType, String? storeId, String? subcategoryId})
    >((ref, params) async {
      final repo = ref.watch(catalogRepositoryProvider);
      final paginated = await repo.getProducts(
        miniAppType: params.miniAppType,
        storeId: params.storeId != null ? int.tryParse(params.storeId!) : null,
        subcategoryId: params.subcategoryId != null
            ? int.tryParse(params.subcategoryId!)
            : null,
      );
      return paginated.items;
    });

/// Provider for products filtered by collection (async — API)
final miniAppCollectionProductsProvider =
    FutureProvider.family<
      List<MiniAppProduct>,
      ({
        MiniAppType miniAppType,
        String? storeId,
        String? subcategoryId,
        String collectionId,
      })
    >((ref, params) async {
      final repo = ref.watch(catalogRepositoryProvider);
      final paginated = await repo.getProducts(
        miniAppType: params.miniAppType,
        storeId: params.storeId != null ? int.tryParse(params.storeId!) : null,
        subcategoryId: params.subcategoryId != null
            ? int.tryParse(params.subcategoryId!)
            : null,
        collectionId: int.tryParse(params.collectionId),
      );
      return paginated.items;
    });

/// Provider for services (toX only) — keep as empty until service API exists
final miniAppServicesProvider =
    Provider.family<List<MiniAppService>, ({String? subcategoryId})>((
      ref,
      params,
    ) {
      // TODO: Wire up when a services endpoint is added to the backend
      return [];
    });

/// Mutable cart state map
final Map<MiniAppType, MiniAppCart> _cartStates = {};

/// Cart provider that exposes mutable cart state
final miniAppCartProvider = Provider.family<MiniAppCart, MiniAppType>((
  ref,
  miniAppType,
) {
  return _cartStates[miniAppType] ?? MiniAppCart.empty();
});

/// Cart notifier provider for mutations
final miniAppCartNotifierProvider =
    Provider.family<MiniAppCartController, MiniAppType>((ref, miniAppType) {
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
final miniAppCartItemCountProvider = Provider.family<int, MiniAppType>((
  ref,
  miniAppType,
) {
  final cart = ref.watch(miniAppCartProvider(miniAppType));
  return cart.totalItems;
});

/// Provider for cart total
final miniAppCartTotalProvider = Provider.family<double, MiniAppType>((
  ref,
  miniAppType,
) {
  final cart = ref.watch(miniAppCartProvider(miniAppType));
  return cart.totalPrice;
});

/// Provider to get quantity of a specific product in cart
final productCartQuantityProvider =
    Provider.family<int, ({MiniAppType miniAppType, String productId})>((
      ref,
      params,
    ) {
      final cart = ref.watch(miniAppCartProvider(params.miniAppType));
      return cart.getQuantity(params.productId);
    });

/// Provider for recommended products (async — API, is_featured=true)
final recommendedProductsProvider =
    FutureProvider.family<
      List<MiniAppProduct>,
      ({MiniAppType miniAppType, String? storeId})
    >((ref, params) async {
      final repo = ref.watch(catalogRepositoryProvider);
      return repo.getRecommendedProducts(
        miniAppType: params.miniAppType,
        storeId: params.storeId != null ? int.tryParse(params.storeId!) : null,
      );
    });

/// Provider for search query
final miniAppSearchQueryProvider = StateProvider.family<String, MiniAppType>(
  (ref, miniAppType) => '',
);

/// Provider for filtered products based on search (async — API)
final filteredProductsProvider =
    FutureProvider.family<
      List<MiniAppProduct>,
      ({
        MiniAppType miniAppType,
        String? storeId,
        String? subcategoryId,
        String searchQuery,
      })
    >((ref, params) async {
      final repo = ref.watch(catalogRepositoryProvider);
      final paginated = await repo.getProducts(
        miniAppType: params.miniAppType,
        storeId: params.storeId != null ? int.tryParse(params.storeId!) : null,
        subcategoryId: params.subcategoryId != null
            ? int.tryParse(params.subcategoryId!)
            : null,
        search: params.searchQuery.isNotEmpty ? params.searchQuery : null,
      );
      return paginated.items;
    });

/// Provider for controlling the active tab index in mini-app shell
/// Used by child screens (cart, map) to switch tabs programmatically
final miniAppActiveTabIndexProvider = StateProvider.family<int, MiniAppType>(
  (ref, miniAppType) => 0,
);
