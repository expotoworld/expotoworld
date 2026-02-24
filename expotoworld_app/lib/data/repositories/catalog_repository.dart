/// Catalog Repository
///
/// Coordinates between the raw [CatalogApi] data source and the domain
/// models.  Handles JSON deserialization and domain-level transformations
/// so consumers (providers / screens) work with typed Dart objects only.
library;

import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../portals/consumer/mini_apps/domain/enums/mini_app_type.dart';
import '../../portals/consumer/mini_apps/domain/models/product_model.dart';
import '../../portals/consumer/mini_apps/domain/models/store_model.dart';
import '../models/catalog/paginated_response.dart';
import '../sources/catalog/catalog_api.dart';

/// Provider
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final api = ref.watch(catalogApiProvider);
  return CatalogRepository(api: api);
});

/// Repository for the public catalog.
class CatalogRepository {
  final CatalogApi _api;

  CatalogRepository({required CatalogApi api}) : _api = api;

  // ───────────────────────── Stores ─────────────────────────

  /// Fetch all stores for a given [miniAppType].
  ///
  /// Returns the full first page (up to [pageSize] items).
  Future<List<MiniAppStore>> getStores(
    MiniAppType miniAppType, {
    StoreType? storeType,
    int pageSize = 50,
  }) async {
    try {
      final json = await _api.listStores(
        etwMiniAppType: miniAppType.apiValue,
        etwStoreType: storeType?.apiValue,
        pageSize: pageSize,
      );

      final paginated = PaginatedResponse<MiniAppStore>.fromJson(
        json,
        (item) => MiniAppStore.fromJson(item),
      );
      return paginated.items;
    } catch (e, st) {
      developer.log(
        'Failed to fetch stores for ${miniAppType.name}',
        name: 'CatalogRepository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetch a single store by ID.
  Future<MiniAppStore> getStore(int storeId) async {
    try {
      final json = await _api.getStore(storeId);
      return MiniAppStore.fromJson(json);
    } catch (e, st) {
      developer.log(
        'Failed to fetch store $storeId',
        name: 'CatalogRepository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ───────────────────────── Categories ─────────────────────────

  /// Fetch all categories for a [miniAppType].
  ///
  /// If [storeId] is given, categories are scoped to that store.
  Future<List<MiniAppCategory>> getCategories(
    MiniAppType miniAppType, {
    int? storeId,
    int pageSize = 50,
  }) async {
    try {
      final json = await _api.listCategories(
        etwMiniAppType: miniAppType.apiValue,
        storeId: storeId,
        pageSize: pageSize,
      );

      final paginated = PaginatedResponse<MiniAppCategory>.fromJson(
        json,
        (item) => MiniAppCategory.fromJson(item),
      );
      return paginated.items;
    } catch (e, st) {
      developer.log(
        'Failed to fetch categories for ${miniAppType.name}',
        name: 'CatalogRepository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ───────────────────────── Subcategories ─────────────────────────

  /// Fetch subcategories for a specific [categoryId].
  ///
  /// The public API returns a plain array (bounded per category),
  /// so we deserialize directly without pagination wrapping.
  Future<List<MiniAppSubcategory>> getSubcategories(int categoryId) async {
    try {
      final json = await _api.listSubcategories(categoryId);

      return json
          .cast<Map<String, dynamic>>()
          .map((item) => MiniAppSubcategory.fromJson(item))
          .toList();
    } catch (e, st) {
      developer.log(
        'Failed to fetch subcategories for category $categoryId',
        name: 'CatalogRepository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ───────────────────────── Collections ─────────────────────────

  /// Fetch collections for a specific [subcategoryId].
  ///
  /// The public API returns a plain array of active collections,
  /// so we deserialize directly without pagination wrapping.
  Future<List<MiniAppCollection>> getCollections(int subcategoryId) async {
    try {
      final json = await _api.listCollections(subcategoryId);

      return json
          .cast<Map<String, dynamic>>()
          .map((item) => MiniAppCollection.fromJson(item))
          .toList();
    } catch (e, st) {
      developer.log(
        'Failed to fetch collections for subcategory $subcategoryId',
        name: 'CatalogRepository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ───────────────────────── Products ─────────────────────────

  /// Fetch products with flexible filtering.
  ///
  /// At minimum you should provide either [storeId] + [subcategoryId],
  /// or [miniAppType] for a broader list.
  Future<PaginatedResponse<MiniAppProduct>> getProducts({
    MiniAppType? miniAppType,
    int? storeId,
    int? categoryId,
    int? subcategoryId,
    int? collectionId,
    String? search,
    bool? isFeatured,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final json = await _api.listProducts(
        etwMiniAppType: miniAppType?.apiValue,
        storeId: storeId,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        collectionId: collectionId,
        search: search,
        isFeatured: isFeatured,
        page: page,
        pageSize: pageSize,
      );

      return PaginatedResponse<MiniAppProduct>.fromJson(
        json,
        (item) => MiniAppProduct.fromJson(item),
      );
    } catch (e, st) {
      developer.log(
        'Failed to fetch products',
        name: 'CatalogRepository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Convenience: fetch only featured / recommended products.
  Future<List<MiniAppProduct>> getRecommendedProducts({
    required MiniAppType miniAppType,
    int? storeId,
    int pageSize = 10,
  }) async {
    final paginated = await getProducts(
      miniAppType: miniAppType,
      storeId: storeId,
      isFeatured: true,
      pageSize: pageSize,
    );
    return paginated.items;
  }

  /// Fetch a single product with full relations (attributes, images, etc.).
  Future<MiniAppProduct> getProduct(int productId) async {
    try {
      final json = await _api.getProduct(productId);
      return MiniAppProduct.fromJson(json);
    } catch (e, st) {
      developer.log(
        'Failed to fetch product $productId',
        name: 'CatalogRepository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetch child / variant products of a parent.
  ///
  /// The public API returns a plain array (bounded variants per parent),
  /// so we deserialize directly without pagination wrapping.
  Future<List<MiniAppProduct>> getProductChildren(int parentId) async {
    try {
      final json = await _api.getProductChildren(parentId);

      return json
          .cast<Map<String, dynamic>>()
          .map((item) => MiniAppProduct.fromJson(item))
          .toList();
    } catch (e, st) {
      developer.log(
        'Failed to fetch children of product $parentId',
        name: 'CatalogRepository',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
