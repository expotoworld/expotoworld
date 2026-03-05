/// Catalog API Data Source
///
/// Thin wrapper around [CatalogApiClient] that calls the public catalog
/// endpoints and returns raw JSON maps.  Deserialization is done in the
/// repository / domain layer so this file stays lean.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_config.dart';
import '../../../core/api/catalog_api_client.dart';

/// Provider
final catalogApiProvider = Provider<CatalogApi>((ref) {
  final client = ref.watch(catalogApiClientProvider);
  return CatalogApi(client: client);
});

/// Data source for the public catalog service.
class CatalogApi {
  final CatalogApiClient _client;

  CatalogApi({required CatalogApiClient client}) : _client = client;

  // ───────────────────────── Stores ─────────────────────────

  /// List stores with optional filters.
  ///
  /// Query params:  `etw_store_type`, `etw_mini_app_type`, `region_id`,
  ///                `search`, `page`, `page_size`.
  Future<Map<String, dynamic>> listStores({
    String? etwStoreType,
    String? etwMiniAppType,
    int? regionId,
    String? search,
    int page = 1,
    int pageSize = 50,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (etwStoreType != null) 'etw_store_type': etwStoreType,
      if (etwMiniAppType != null) 'etw_mini_app_type': etwMiniAppType,
      if (regionId != null) 'region_id': regionId,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _client.get<Map<String, dynamic>>(
      CatalogEndpoints.stores,
      queryParameters: qp,
    );
    return response.data!;
  }

  /// Get a single store by its ID.
  Future<Map<String, dynamic>> getStore(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      CatalogEndpoints.store(id),
    );
    return response.data!;
  }

  // ───────────────────────── Categories ─────────────────────────

  /// List categories with optional filters.
  ///
  /// Query params: `store_id`, `etw_store_type`, `etw_mini_app_type`,
  ///               `page`, `page_size`.
  Future<Map<String, dynamic>> listCategories({
    int? storeId,
    String? etwStoreType,
    String? etwMiniAppType,
    int page = 1,
    int pageSize = 50,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (storeId != null) 'store_id': storeId,
      if (etwStoreType != null) 'etw_store_type': etwStoreType,
      if (etwMiniAppType != null) 'etw_mini_app_type': etwMiniAppType,
    };

    final response = await _client.get<Map<String, dynamic>>(
      CatalogEndpoints.categories,
      queryParameters: qp,
    );
    return response.data!;
  }

  /// Get the full category → subcategory tree.
  Future<List<dynamic>> getCategoryTree({
    int? storeId,
    String? etwStoreType,
    String? etwMiniAppType,
  }) async {
    final qp = <String, dynamic>{
      if (storeId != null) 'store_id': storeId,
      if (etwStoreType != null) 'etw_store_type': etwStoreType,
      if (etwMiniAppType != null) 'etw_mini_app_type': etwMiniAppType,
    };

    final response = await _client.get<List<dynamic>>(
      CatalogEndpoints.categoryTree,
      queryParameters: qp,
    );
    return response.data!;
  }

  /// Get a single category by its ID.
  Future<Map<String, dynamic>> getCategory(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      CatalogEndpoints.category(id),
    );
    return response.data!;
  }

  /// List subcategories under a category.
  ///
  /// The public backend returns a plain JSON array (not paginated),
  /// consistent with the bounded nature of subcategories per category.
  Future<List<dynamic>> listSubcategories(int categoryId) async {
    final response = await _client.get<List<dynamic>>(
      CatalogEndpoints.subcategories(categoryId),
    );
    return response.data!;
  }

  // ───────────────────────── Collections ─────────────────────────

  /// List collections under a subcategory.
  ///
  /// The public backend returns a plain JSON array of active collections,
  /// consistent with the bounded nature of collections per subcategory.
  Future<List<dynamic>> listCollections(int subcategoryId) async {
    final response = await _client.get<List<dynamic>>(
      CatalogEndpoints.collections(subcategoryId),
    );
    return response.data!;
  }

  // ───────────────────────── Subcollections ─────────────────────────

  /// List subcollections under a collection.
  ///
  /// The public backend returns a plain JSON array of active subcollections,
  /// consistent with the bounded nature of subcollections per collection.
  Future<List<dynamic>> listSubcollections(int collectionId) async {
    final response = await _client.get<List<dynamic>>(
      CatalogEndpoints.subcollections(collectionId),
    );
    return response.data!;
  }

  // ───────────────────────── Products ─────────────────────────

  /// List products with optional filters.
  ///
  /// Query params: `store_id`, `category_id`, `subcategory_id`,
  ///   `etw_store_type`, `etw_mini_app_type`, `search`,
  ///   `min_price`, `max_price`, `is_featured`, `page`, `page_size`.
  Future<Map<String, dynamic>> listProducts({
    int? storeId,
    int? categoryId,
    int? subcategoryId,
    int? collectionId,
    int? subcollectionId,
    String? etwStoreType,
    String? etwMiniAppType,
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? isFeatured,
    int page = 1,
    int pageSize = 20,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (storeId != null) 'store_id': storeId,
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (collectionId != null) 'collection_id': collectionId,
      if (subcollectionId != null) 'subcollection_id': subcollectionId,
      if (etwStoreType != null) 'etw_store_type': etwStoreType,
      if (etwMiniAppType != null) 'etw_mini_app_type': etwMiniAppType,
      if (search != null && search.isNotEmpty) 'search': search,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      if (isFeatured != null) 'is_featured': isFeatured,
    };

    final response = await _client.get<Map<String, dynamic>>(
      CatalogEndpoints.products,
      queryParameters: qp,
    );
    return response.data!;
  }

  /// Get a single product (with relations).
  Future<Map<String, dynamic>> getProduct(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      CatalogEndpoints.product(id),
    );
    return response.data!;
  }

  /// List child/variant products of a parent product.
  ///
  /// The public backend returns a plain JSON array of active child products,
  /// consistent with the bounded nature of variants per parent.
  Future<List<dynamic>> getProductChildren(int id) async {
    final response = await _client.get<List<dynamic>>(
      CatalogEndpoints.productChildren(id),
    );
    return response.data!;
  }
}
